require 'nokogiri'

module Awestruct
  module ContextHelper

    def html_to_text(str)
      str.gsub( /<[^>]+>/, '' ).gsub( /&nbsp;/, ' ' )
    end

    def clean_html(str)
      str.gsub( /&nbsp;/, ' ' )
    end

    def without_images(str)
      str.gsub(/<img[^>]+>/,'').gsub(/<a[^>]+>([^<]*)<\/a>/, '\1')
    end

    def close_tags(s)
      stack = []
      s.scan(/<\/?[^>]+>/).each do |tag|
        if tag[1] != '/'
          tag = tag[1..-1].scan(/\w+/).first
          stack = [ tag ] + stack
        else
          tag = tag[2..-1].scan(/\w+/).first
          if stack[0] == tag
            stack = stack.drop(1)
          else
            raise "Malformed HTML expected #{tag[0]} but got #{tag} '#{s}'"
          end
        end
      end
      stack.inject(s) { |memo,tag| memo += "</#{tag}>" }
    end

    def summarize(text, numwords=20, ellipsis='...')
      close_tags(text.split(/ /)[0, numwords].join(' ') + ellipsis)
    end

    def fully_qualify_urls(base_url, text)
      doc = Nokogiri::HTML(text)

      doc.xpath( "//a" ).each do |a|
        a['href'] = fix_url( base_url, a['href'] )
      end
      doc.xpath( "//link" ).each do |link|
        link['href'] = fix_url( base_url, link['href'] )
      end
      doc.xpath( "//img" ).each do |img|
        img['src'] = fix_url( base_url, img['src'] )
      end
      return doc.to_html
    end

    def fix_url(base_url, url)
      return url unless ( url =~ /^\// )
      "#{base_url}#{url}"
    end
  end

end
