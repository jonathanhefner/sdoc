require "base64"
require "nokogiri"

module SDoc::SearchIndex
  extend self

  def generate(rdoc_modules)
    # RDoc duplicates RDoc::MethodAttr instances when modules are aliased by
    # assigning to a constant. For example, `MyBar = Foo::Bar` will duplicate
    # all of Foo::Bar's RDoc::MethodAttr instances.
    rdoc_objects = rdoc_modules + rdoc_modules.flat_map(&:method_list).uniq

    bigram_sets = rdoc_objects.map { |rdoc_object| derive_bigrams(rdoc_object.full_name) }
    bigram_bit_positions = compile_bigrams(bigram_sets)
    bit_weights = compute_bit_weights(bigram_bit_positions)
    entries = []

    rdoc_objects.zip(bigram_sets) do |rdoc_object, bigrams|
      entries << [
        generate_fingerprint(bigrams, bigram_bit_positions), # Fingerprint
        1.0 / rdoc_object.full_name.length, # Tie-breaker bonus
        rdoc_object.path, # URL
      ]

      if rdoc_object.is_a?(RDoc::ClassModule)
        entries.last << name_for(rdoc_object) # Class name
        entries.last << nil # Method name
      else
        entries.last << name_for(rdoc_object.parent) # Class name
        entries.last << name_for(rdoc_object) # Method name

        # Give slightly more weight to the method name so that short method
        # name + long module name ranks higher than long method name + short
        # module name.
        entries.last[1] = entries.last[1] * 0.97 + (1.0 / rdoc_object.name.length) * 0.03
      end

      if description = truncate_description(rdoc_object.description, 140)
        entries.last << description # Summary
      end
    end

    { "bigrams" => bigram_bit_positions, "weights" => bit_weights, "entries" => entries }
  end

  def derive_bigrams(name)
    # Example: "ActiveSupport::Cache::Store#fetch" => [":ActiveSupport", ":Cache", ":Store", "#fetch"]
    strings = ":#{name}".split(/:(?=:)|(?=#)/)
    # Example: ":HashWithIndifferentAccess" => ":HWIA"
    strings.concat(strings.map { |string| string.gsub(/([A-Z])[a-z]+/, '\1') })
    # Example: ":HWIA" => ":hwia"
    strings.concat(strings.map(&:downcase))
    # Example: "#fetch_values" => "#fetchvalues"
    strings.concat(strings.map { |string| string.tr("_", "") })
    # Example: ":controller_name" => [" controller, " name"]
    strings.concat(strings.flat_map { |string| string.tr(":#_", " ").split(/(?= )/) })

    if method_name_first_char = name[/[:#]([^:])[^:#]*\z/, 1]
      # Example: "ActionController::Metal::controller_name" => ".c"
      strings << ".#{method_name_first_char}"
      # Example: "ActionController::Metal::controller_name" => "e("
      strings << "#{name[-1]}("
    else
      strings << " :" # This bigram signifies a module.
    end

    strings.flat_map { |string| string.each_char.each_cons(2).map(&:join) }.uniq
  end

  def compile_bigrams(bigram_sets)
    # Assign each bigram a bit position based on its rarity. More common bigrams
    # come first. This reduces the average number of bytes required to store a
    # fingerprint.
    bigram_sets.flatten.tally.sort_by(&:last).reverse.map(&:first).each_with_index.to_h
  end

  BIGRAM_PATTERN_WEIGHTS = {
    /[^a-z]/ => 2, # Bonus point for non-lowercase-alpha chars because they show intentionality.
    /^ / => 3, # More bonus points for matching start of token because it shows more intentionality.
    /^:/ => 4, # Slightly more points for start of module because it shows even more intentionality.
    / :/ => 3, # When query includes " :" (or starts with ":"), slightly prefer modules.
    /[#.(]/ => 50, # When query includes "#", ".", or "(", strongly prefer methods.
  }

  def compute_bit_weights(bigram_bit_positions)
    bigram_bit_positions.uniq(&:last).sort_by(&:last).map do |bigram, _position|
      BIGRAM_PATTERN_WEIGHTS.map { |pattern, weight| bigram.match?(pattern) ? weight : 1 }.max
    end
  end

  def generate_fingerprint(bigrams, bigram_bit_positions)
    bit_positions = bigrams.map(&bigram_bit_positions)
    byte_count = ((bit_positions.max + 1) / 8.0).ceil
    bytes = [0] * byte_count

    bit_positions.each do |position|
      bytes[position / 8] |= 1 << (position % 8)
    end

    bytes
  end

  def name_for(rdoc_object)
    case rdoc_object
    when RDoc::MethodAttr
      sigil = rdoc_object.singleton ? "::" : "#"
      params = rdoc_object.call_seq ? "(...)" : rdoc_object.params
      "#{sigil}#{rdoc_object.name}#{params}"
    else
      rdoc_object.full_name
    end
  end

  def truncate_description(description, limit)
    return if description.empty?
    leading_paragraph = Nokogiri::HTML.fragment(description).at_css("h1 + p, p:first-child")
    return unless leading_paragraph

    # Replace links with their inner HTML
    leading_paragraph.css("a").each { |a| a.replace(a.children) }

    # Truncate text (but not in <code> elements)
    leading_paragraph.traverse do |node|
      if limit <= 0
        node.remove if node.children.empty?
      elsif node.text?
        limit -= node.content.length
        if limit < 0 && node.parent.name != "code"
          node.content = node.content[0..limit].sub(/(?:\W+|\W*\w+)\Z/, "")
        end
      end
    end

    # Append ellipsis if truncated or if paragraph refers to a subsequent block
    if limit < 0 || leading_paragraph.inner_text.end_with?(":")
      leading_paragraph.add_child("...")
    end

    leading_paragraph.inner_html
  end
end
