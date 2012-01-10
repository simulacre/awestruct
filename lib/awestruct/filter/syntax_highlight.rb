require "cgi"
require "nokogiri"

module Awestruct
  class Filter
    module SyntaxHighlight
      include HighlightCode
      extend HighlightCode
      extend self

      # Searches for any <code class="[js, ruby, etc.,.]> tags and replaces them with a syntax highlighted version.
      # The original contents of the code block will be inserted in the page surrounded by <noscript> tags.
      def post_render(page)
        replaced = 0
        doc  = Nokogiri::HTML.fragment(page.content)
        doc.children.each do |root|
          root.xpath(".//code").each do |code|
            # if we've already processed this code block then it's grandparent will be <td class="code">
            next if code.parent && code.parent.parent && code.parent.parent['class'] == 'code'

            code.parent.before("<noscript>#{code.text}</noscript>")

            raw = (CGI.unescapeHTML(code.inner_html)).chomp.freeze
            if code['class']
              lang = case code['class']
              when 'pl'
                'perl'
              when 'yml'
                'yaml'
              when 'shell'
                'bash'
              else
                code['class']
              end

              hed = highlight(raw, lang)
              ["pre", "p"].include?(code.parent.node_name) ?  code.parent.swap(hed) : code.swap(hed)
              replaced += 1
            elsif code.parent.name != "pre"
              code.replace("<pre>#{code}</pre>")
              replaced += 1
            end # code["class"]
          end
        end # root

        (replaced == 0 ? page.content : doc.to_html)
      end # post_render(page)
    end # module::SyntaxHighlight
  end # class::Filter
end # module::Awestruct
