require "spec_helper"

describe "RDoc monkey patches" do
  describe RDoc::TopLevel do
    it "supports setting #path" do
      top_level = rdoc_top_level_for("class Foo; end")

      _(top_level.path).wont_be_nil

      top_level.path = "some/path"
      _(top_level.path).must_equal "some/path"
    end
  end

  describe RDoc::Markup::ToHtmlCrossref do
    it "prevents unintentional ref links" do
      description = rdoc_top_level_for(<<~RUBY).find_module_named("CoolApp").description
        module ERB; end
        module Rails; end

        # CoolApp uses Rails and ERB. See ::Rails. See also ::ERB.
        module CoolApp; end
      RUBY

      _(description).must_match %r"<a href=.+?><code>CoolApp</code></a> uses Rails and ERB"
      _(description).must_match %r"See <a href=.+?><code>::Rails</code></a>"
      _(description).must_match %r"See also <a href=.+?><code>::ERB</code></a>"
    end

    it "styles ref links that look like code" do
      description = rdoc_top_level_for(<<~RUBY).find_module_named("Foo").description
        # Some of {Foo}[rdoc-ref:Foo]'s methods can be called with multiple
        # arguments, such as {bar(x, y)}[rdoc-ref:#bar].
        #
        # But {baz cannot}[rdoc-ref:#baz] and {qux (also) cannot}[rdoc-ref:#qux].
        class Foo
          def bar(x, y); end
          def baz; end
          def qux; end
        end
      RUBY

      _(description).must_match %r"Some of <a href=.+?><code>Foo</code></a>"
      _(description).must_match %r"such as <a href=.+?><code>bar\(x, y\)</code></a>"

      _(description).must_match %r"But <a href=.+?>baz cannot</a>"
      _(description).must_match %r"and <a href=.+?>qux \(also\) cannot</a>"
    end
  end
end
