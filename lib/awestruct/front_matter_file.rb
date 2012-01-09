require "tilt"
Dir[File.expand_path('../front_matter_file/**/*', __FILE__)].each { |lib| require lib }
require "liquid"
require "awestruct/liquid/tags"
require "awestruct/filter"

module Awestruct
  class FrontMatterFile < OpenStruct
    attr_reader :site
    attr_reader :raw_page_content
    attr_reader :template

    class << self
      # Load a new front_matter file for the site from a source path if a suitable
      # template parser for the source path is found.
      # @return [FrontMatterFile, nil] nil if a suitable parse is not found.
      def load(site, source_path, relative_source_path, options = {})
        @cache ||= {}
        return @cache[source_path] if @cache[source_path]
        return nil unless Tilt[source_path]
        return @cache[source_path] = new(site, source_path, relative_source_path, options = {})
      end

      def s_to_class(s, start = self)
        s.split('::').map(&:to_sym).inject(self) do |p,c|
          return nil unless p.const_defined?(c)
          p.const_get(c)
        end
      end

      def filter(filter, template_type = :any)
        raise ArgumentError.new("filter must respond to pre_render or post_render") unless [:pre_render, :post_render].any?{|k| filter.respond_to?(k) }
        @filters ||= {:any => [], :not => {}}
        if template_type.is_a?(Hash)
          raise ArgumentError.new("filter type :not is required when given a Hash") unless template_type[:not]
          template_type[:not] = [template_type[:not]] unless template_type[:not].is_a?(Array)
          template_type[:not].each do |nt|
            @filters[:not][nt] ||= []
            @filters[:not][nt].push(filter) unless @filters[:not][nt].include?(filter)
          end # nt
        else
          @filters[template_type] ||= []
          @filters[template_type].push(filter) unless @filters[template_type].include?(filter)
        end # template_type.is_a?(Hash)
      end # filter

      def pre_filter(template_type = :any, &blk)
        filter(Filter.new{ pre_render(&blk) }, template_type)
      end

      def post_filter(template_type = :any, &blk)
        filter(Filter.new{ post_render(&blk) }, template_type)
      end

      def filters(template_type = nil)
        @filters ||= { :any => [], :not => {} }
        return @filters if template_type.nil?
        nots = @filters[:not].select{ |k,fs| k == template_type }.values.flatten
        ((@filters[template_type] ||= []) |
          @filters[:any] |
          @filters[:not].select{|k,fs| k != template_type }.values).flatten.reject{|f| nots.include?(f) }
      end # filters(template_type)

      def pre_filters(template_type)
        filters(template_type).select{|f| f.respond_to?(:pre_render) }
      end # pre_filters(template_type)

      def post_filters(template_type)
        filters(template_type).select{|f| f.respond_to?(:post_render) }
      end # pre_filters(template_type)
    end # class << self


    # Load a front_matter file with a suitable template parser.
    # If the file is not a Liquid template it will be preproccessed by a Liquid
    # template parser, so all templates can include Liquid tags.
    def initialize(site, source_path, relative_source_path, options = {})
      super({})
      @raw_page_content               = ''
      @content_start_line             = 1
      @site                           = site
      self.source_path                = source_path
      self.relative_source_path       = relative_source_path

      @content, self.front_matter = *load_page
      self.front_matter.each { |k,v| self.send( "#{k}=", v ) }

      Tilt.new(source_path, @content_start_line) do |template|
        @template       = template
        @template_type  = template.class.to_s.split('Tilt::',2)[-1]
        (mixin = self.class.s_to_class(@template_type)) && extend(mixin)
        template.options.merge!(opts.merge(user_rules))
        pre_filters.each {|filter| @content = filter.pre_render(self) }
        @content
      end

      # while pre_render filters process @content needs to be available # after that it's
      # not available until #content is called again, triggering the post_render filters
      # code smell!
      @content = nil

      unless ( relative_source_path.nil? )
        dir_name         = File.dirname( relative_source_path )
        self.output_path = dir_name == "." ? output_filename : File.join( dir_name, output_filename )
      end
    end

    def render(context, locals = {}, &blk)
      @content = @template.render(context, locals, &blk)
      post_filters.each { |filter| @content = filter.post_render(self) }
      @content
    end

    def content
      @content ||= render(site.engine.create_context(self))
    end

    # Converts the front_matter filename to an output filename with the correct extension.
    # I'm surprised that this isn't provided by Tilt.
    # @todo use Tilt.mappings to correctly set filename extension for templates that aren't sass, less, markdown, or haml
    def output_filename
      case @template
      when Tilt::HamlTemplate
        File.basename(self.source_path, '.haml')

      when Tilt::ScssTemplate, Tilt::SassTemplate, Tilt::LessTemplate
        [".sass", ".scss", ".less"].inject(self.source_path){|f,e| File.basename(f, e) } + '.css'

      when Tilt::RDiscountTemplate, Tilt::RedcarpetTemplate, Tilt::RedcarpetTemplate::Redcarpet1, Tilt::RedcarpetTemplate::Redcarpet2, Tilt::BlueClothTemplate, Tilt::MarukuTemplate, Tilt::KramdownTemplate
        [".md", ".mkd", ".markdown"].inject(self.source_path){|f,e| File.basename(f, e) } + '.html'

      else
        File.basename(self.source_path).reverse.split(".", 2)[-1].reverse
      end
    end

    def output_extension
      File.extname( output_filename )
    end



    # pre_filter do |page|
    #   page.extend BacktickCodeBlock
    #   page.render_code_block(page.content)
    # end

    pre_filter(:not => Tilt::LiquidTemplate) do |page|
      Tilt.new("#{page.source_path}.liquid", page.content_start_line){ page.content }.render
    end


  protected

    def pre_filters
      self.class.pre_filters(@template.class)
    end

    def post_filters
      self.class.post_filters(@template.class)
    end


    # Retreive the source file, extract the YAML and return the raw template content.
    # @return [String]
    def load_page
      full_content      = File.binread(self.source_path)
      full_content.force_encoding(@site.encoding) if @site.encoding && full_content.encoding != @site.encoding
      yaml_content      = []
      raw_content = []

      begin
        lines = full_content.each_line
        if lines.peek.strip == '---'
          lines.next
          yaml_content << lines.next while lines.peek.strip != '---'
          lines.next
          yaml_content = yaml_content
        end # line.peek.strip == '---'
        raw_content << lines.next while true
      rescue StopIteration # we're done
      rescue Exception => e
        e.set_backtrace(e.backtrace.unshift("#{source_path}:#{@header_line_cnt + raw_content.count}"))
        raise e
      ensure
        @header_line_cnt    = yaml_content.count + 2
        @content_start_line = lines.count - raw_content.count + 1
        raw_content         = raw_content.join
      end

      begin
        front_matter = YAML.load( yaml_content.join ) || {}
      rescue => e
        puts "error reading #{self}: #{e}"
      end

      [raw_content, front_matter]
    end

    # Options to pass to the Tilt template.
    # They can be augmented by implementing a module that corresponds to the Tilt template
    # and defining an opts method.
    # @return [Hash]
    def opts
      {}
    end

    # Retrieve options from the site configuration that should be passed to the Tilt template.
    # It will look under site.[template_name]_rules. The rules will just be taken as they
    # are and passed down. Implementing modules can override this method to enforce some kind
    # of structure, etc.,.
    # @return [Hash]
    def user_rules
      site.send( @template_type.split("::")[-1].downcase.split("template")[0] + "_rules" ) || {}
    end
  end # class::FrontMatterFile < OpenStruct

  FrontMatterFile.filter Filter::SyntaxHighlight, :not =>  [Tilt::ScssTemplate, Tilt::SassTemplate, Tilt::LessTemplate]
end
