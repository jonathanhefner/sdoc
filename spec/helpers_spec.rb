require "spec_helper"

describe SDoc::Helpers do
  before :each do
    @helpers = Class.new do
      include SDoc::Helpers
    end.new
  end

  describe "#strip_tags" do
    it "should strip out HTML tags from the given string" do
      strings = [
        [ %(<strong>Hello world</strong>),                                      "Hello world"          ],
        [ %(<a href="Streams.html">Streams</a> are great),                      "Streams are great"    ],
        [ %(<a href="https://github.com?x=1&y=2#123">zzak/sdoc</a> Standalone), "zzak/sdoc Standalone" ],
        [ %(<h1 id="module-AR::Cb-label-Foo+Bar">AR Cb</h1>),                   "AR Cb"                ],
        [ %(<a href="../Base.html">Base</a>),                                   "Base"                 ],
        [ %(Some<br>\ntext),                                                    "Some\ntext"           ]
      ]

      strings.each do |(html, stripped)|
        _(@helpers.strip_tags(html)).must_equal stripped
      end
    end
  end

  describe "#truncate" do
    it "should truncate the given text around a given length" do
      _(@helpers.truncate("Hello world", length: 5)).must_equal "Hello."
    end
  end

  describe "#highlight_code_snippets" do
    it "guesses languages and highlights code snippets" do
      doc = <<~HTML
        <p>Ruby:</p>
        <pre><code>1 + 1</code></pre>
        <p>ERB:</p>
        <pre><code>&lt;%= 1 + 1 %&gt;</code></pre>
      HTML

      expected = <<~HTML
        <p>Ruby:</p>
        <pre><code class="highlight ruby">#{@helpers.highlight_code("1 + 1", "ruby")}</code></pre>
        <p>ERB:</p>
        <pre><code class="highlight erb">#{@helpers.highlight_code("<%= 1 + 1 %>", "erb")}</code></pre>
      HTML

      _(@helpers.highlight_code_snippets(doc)).must_equal expected
    end
  end

  describe "#highlight_code" do
    it "returns highlighted HTML" do
      _(@helpers.highlight_code("1 + 1", "ruby")).must_equal \
        %{<span class="mi">1</span> <span class="o">+</span> <span class="mi">1</span>}

      _(@helpers.highlight_code("$ rails s", "console")).must_equal \
        %{<span class="gp">$</span><span class="w"> </span>rails s}
    end
  end

  describe "#guess_code_language" do
    it "guesses plaintext for ASCII-art tables" do
      _(@helpers.guess_code_language(<<~TABLE)).must_equal "plaintext"
        a | b
        --+--
        1 | 2
      TABLE

      _(@helpers.guess_code_language(<<~TABLE)).must_equal "plaintext"
        a | b
        --|--
        1 | 2
      TABLE
    end

    it "guesses plaintext for routes listings" do
      _(@helpers.guess_code_language(<<~ROUTES)).must_equal "plaintext"
        post GET    /posts/:id(.:format)      posts#show
             DELETE /posts/:id(.:format)      posts#destroy
      ROUTES

      _(@helpers.guess_code_language(<<~ROUTES)).must_equal "plaintext"
        DELETE /posts/:id
      ROUTES
    end

    it "guesses sql for SQL queries" do
      _(@helpers.guess_code_language(<<~SQL)).must_equal "sql"
        SELECT * FROM posts
      SQL

      _(@helpers.guess_code_language(<<~SQL)).must_equal "sql"
        DELETE FROM posts WHERE id = 1
      SQL
    end

    it "guesses console for CLI sessions" do
      _(@helpers.guess_code_language(<<~SESSION)).must_equal "console"
        $ rails server
        Booting
      SESSION
    end

    it "guesses yaml for YAML" do
      _(@helpers.guess_code_language(<<~YAML)).must_equal "yaml"
        foo:
          bar: 1
      YAML

      _(@helpers.guess_code_language(<<~YAML)).must_equal "yaml"
        foo: # comment
          bar: 1
      YAML

      _(@helpers.guess_code_language(<<~YAML)).must_equal "yaml"
        base: &base
          baz: 1

        foo:
          <<: *base
          bar: 2
      YAML

      _(@helpers.guess_code_language(<<~YAML)).must_equal "yaml"
        foo: |
          bar
      YAML

      _(@helpers.guess_code_language(<<~YAML)).must_equal "yaml"
        foo: >
          bar
      YAML
    end

    it "guesses erb for YAML that includes ERB" do
      _(@helpers.guess_code_language(<<~ERB)).must_equal "erb"
        foo:
          bar: <%= 1 + 1 %>
      ERB
    end

    it "guesses plaintext for YAML that includes ERB and HTML-incompatible markup" do
      _(@helpers.guess_code_language(<<~ERB)).must_equal "plaintext"
        base: &base
          baz: 1

        foo:
          <<: *base
          bar: <%= 1 + 1 %>
      ERB
    end

    it "guesses erb for ERB" do
      _(@helpers.guess_code_language(<<~ERB)).must_equal "erb"
        <%= 1 + 1 %>
      ERB

      _(@helpers.guess_code_language(<<~ERB)).must_equal "erb"
        <% x = 1 + 1 %>
      ERB

      _(@helpers.guess_code_language(<<~ERB)).must_equal "erb"
        <%- x = 1 + 1 -%>
      ERB
    end

    it "guesses erb for HTML" do
      _(@helpers.guess_code_language(<<~HTML)).must_equal "erb"
        <p>1 + 1 = 2</p>
      HTML
    end

    it "guesses erb for HTML that includes ERB" do
      _(@helpers.guess_code_language(<<~ERB)).must_equal "erb"
        <p>1 + 1 = <%= 1 + 1 %></p>
      ERB
    end

    it "guesses ruby for Ruby code" do
      _(@helpers.guess_code_language(<<~RUBY)).must_equal "ruby"
        1 + 1
      RUBY
    end

    it "guesses ruby for Ruby code that includes an ERB string" do
      _(@helpers.guess_code_language(<<~RUBY)).must_equal "ruby"
        ApplicationController.render inline: "<%= 1 + 1 %>"
      RUBY
    end

    it "guesses ruby by default" do
      _(@helpers.guess_code_language(<<~RUBY)).must_equal "ruby"
        f x
      RUBY
    end
  end
end
