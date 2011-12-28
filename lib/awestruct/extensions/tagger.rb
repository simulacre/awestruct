
module Awestruct
  module Extensions
    class Tagger

      class << self
        def page_accessor(attr = nil)
          return (@page_accessor_attr || :tags) if attr.nil?
          @page_accessor_attr = attr
        end
        def link_helper(klass = nil)
          return (@link_helper || TagLinker) if klass.nil?
          @link_helper = klass
        end
      end

      class TagStat
        attr_accessor :pages
        attr_accessor :group
        attr_accessor :primary_page
        def initialize(tag, pages)
          @tag   = tag
          @pages = pages
        end

        def to_s
          @tag
        end
      end

      module TagLinker
        attr_accessor :tags
        def tag_links(delimiter = ', ', style_class = nil)
          class_attr = (style_class ? ' class="' + style_class + '"' : '')
          tags.map{|tag| %Q{<a#{class_attr} href="#{tag.primary_page.url}">#{tag}</a>}}.join(delimiter)
        end
      end

      def initialize(tagged_items_property, input_path, output_path='tags', pagination_opts={})
        @tagged_items_property = tagged_items_property
        @input_path  = input_path
        @output_path = output_path
        @pagination_opts = pagination_opts
      end

      def execute(site)
        @tags ||= {}
        all = site.send( @tagged_items_property )
        return if ( all.nil? || all.empty? )

        all.each do |page|
          tags = page.send(self.class.page_accessor)
          if ( tags && ! tags.empty? )
            tags.each do |tag|
              tag = tag.to_s
              @tags[tag] ||= TagStat.new( tag, [] )
              @tags[tag].pages << page
            end
          end
        end

        all.each do |page|
          page.send("#{self.class.page_accessor}=", (page.send(self.class.page_accessor)||[]).collect{|t| @tags[t]})
          page.extend( self.class.link_helper )
        end

        ordered_tags = @tags.values
        ordered_tags.sort!{|l,r| -(l.pages.size <=> r.pages.size)}
        #ordered_tags = ordered_tags[0,100]
        ordered_tags.sort!{|l,r| l.to_s <=> r.to_s}

        min = 9999
        max = 0

        ordered_tags.each do |tag|
          min = tag.pages.size if ( tag.pages.size < min )
          max = tag.pages.size if ( tag.pages.size > max )
        end

        span = max - min

        if span > 0
          slice = span / 6.0
          ordered_tags.each do |tag|
            adjusted_size = tag.pages.size - min
            scaled_size = adjusted_size / slice
            tag.group = (( tag.pages.size - min ) / slice).ceil
          end
        else
          ordered_tags.each do |tag|
            tag.group = 0
          end
        end

        @tags.values.each do |tag|
          paginator = Awestruct::Extensions::Paginator.new( @tagged_items_property, @input_path, { :remove_input=>false, :output_prefix=>File.join( @output_path, tag.to_s), :collection=>tag.pages, :front_matter => {:tag => tag} }.merge( @pagination_opts ) )
          primary_page = paginator.execute( site )
          tag.primary_page = primary_page
        end

        site.send( "#{@tagged_items_property}_tags=", ordered_tags )
      end
    end
  end
end
