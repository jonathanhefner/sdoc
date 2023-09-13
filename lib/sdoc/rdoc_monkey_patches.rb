require "rdoc"

RDoc::TopLevel.prepend(Module.new do
  attr_writer :path

  def path
    @path ||= super
  end
end)


RDoc::Markup::Formatter.prepend(Module.new do
  def _word_break_code(code)
    code.gsub(%r".::|\w/+(?=\w)|\S\((?!\))", '\0<wbr>')
  end

  def convert_flow(flow)
    if in_tt?
      flow = flow.map { |item| item.is_a?(String) ? _word_break_code(item) : item }
    end

    super
  end
end)


RDoc::Markup::ToHtmlCrossref.prepend(Module.new do
  def cross_reference(name, text = nil, code = true)
    if text
      # Style ref links that look like code, such as `{Rails}[rdoc-ref:Rails]`.
      code ||= !text.include?(" ") || text.match?(/\S\(/)
    elsif name.match?(/\A[A-Z](?:[A-Z]+|[a-z]+)\z/)
      # Prevent unintentional ref links, such as `Rails` or `ERB`.
      return name
    end

    super.sub(%r"(?<=<code>).+(?=</code>)") { |code| _word_break_code(code) }
  end
end)
