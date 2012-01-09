require "cgi"

module Awestruct
  class Filter
    module SyntaxHighlight
      include HighlightCode
      extend HighlightCode
      extend self

      def post_render(page)
        # @todo switch to Nokogiri ASAP because Hpricot is an atrocious piece of shit. It's full of bugs.
        # it fucks up the structure of the html for unrecognized tags, e.g. <article>
        doc = Hpricot(page.content)
        doc.search( "//code" ).each do |code|
          next if code.parent && code.parent.is_a?(Hpricot::Elem) &&
            code.parent.parent && code.parent.parent.is_a?(Hpricot::Elem) &&
            code.parent.parent['class'] == 'code'

          raw = (CGI.unescapeHTML(code.innerHTML)).freeze
          code.after "<noscript>#{raw}</noscript>" if code.next_sibling.nil? || code.next_sibling.name != "noscript"

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
            ["pre", "p"].include?(code.parent.name) ?  code.parent.swap(hed) : code.swap(hed)
          elsif code.parent.name != "pre"
            code.swap("<pre>")
            code.innerHTML = code.to_html
          end # code["class"]
        end

        doc.to_html.tap do |content|
          content.force_encoding(page.content.encoding) if content.encoding != page.content.encoding
        end
      end # post_render(page)
    end # module::SyntaxHighlight
  end # class::Filter
end # module::Awestruct
