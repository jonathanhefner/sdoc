require "nokogiri"
require "rouge"

module SDoc::Helpers
  def each_letter_group(methods, &block)
    group = {:name => '', :methods => []}
    methods.sort{ |a, b| a.name <=> b.name }.each do |method|
      gname = group_name method.name
      if gname != group[:name]
        yield group unless group[:methods].size == 0
        group = {
          :name => gname,
          :methods => []
        }
      end
      group[:methods].push(method)
    end
    yield group unless group[:methods].size == 0
  end

  # Strips out HTML tags from a given string.
  #
  # Example:
  #
  #   strip_tags("<strong>Hello world</strong>") => "Hello world"
  def strip_tags(text)
    text.gsub(%r{</?[^>]+?>}, "")
  end

  # Truncates a given string. It tries to take whole sentences to have
  # a meaningful description for SEO tags.
  #
  # The only available option is +:length+ which defaults to 200.
  def truncate(text, options = {})
    if text
      length = options.fetch(:length, 200)
      stop   = text.rindex(".", length - 1) || length

      "#{text[0, stop]}."
    end
  end

  def horo_canonical_url(canonical_url, context)
    if context == :index
      return "#{canonical_url}/"
    end

    return "#{canonical_url}/#{context.as_href("")}"
  end

  def highlight_code_snippets(doc)
    if doc.include?("</code></pre>")
      fragment = Nokogiri::HTML.fragment(doc)

      fragment.css("pre code").each do |node|
        code = node.inner_text
        language = guess_code_language(code)
        node.inner_html = highlight_code(code, language)
        node.append_class("highlight").append_class(language)
      end

      doc = fragment.to_s
    end

    doc
  end

  def highlight_code(code, language)
    lexer = Rouge::Lexer.find_fancy(language)
    Rouge::Formatters::HTML.format(lexer.lex(code))
  end

  def guess_code_language(code)
    case code
    when /--[+|]--/ # ASCII-art table
      "plaintext"
    when /(?:GET|POST|PUT|PATCH|DELETE|HEAD) +\// # routes listing or HTTP request
      "plaintext"
    when /\A(?:SELECT|INSERT|UPDATE|DELETE|CREATE|ALTER|DROP) /
      "sql"
    when /^\$ /
      "console"
    when /^(?:- )?\w+:(?:\n| [#&|>])/
      if code.include?("<%")
        code.include?("<<:") ? "plaintext" : "erb"
      else
        "yaml"
      end
    when /^ *<[%a-z]/i
      "erb" # also highlights HTML
    else
      "ruby"
    end
  end

protected
  def group_name name
    if match = name.match(/^([a-z])/i)
      match[1].upcase
    else
      '#'
    end
  end
end
