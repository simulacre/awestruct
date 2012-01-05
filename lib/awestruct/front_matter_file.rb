require "tilt"
Dir[File.expand_path('../front_matter_file/**/*', __FILE__)].each { |lib| require lib }

module Awestruct
  class FrontMatterFile < OpenStruct
    attr_reader :site
    attr_reader :raw_page_content
    attr_reader :front_matter

    class << self
      def load(site, source_path, relative_source_path, options = {})
        return nil unless Tilt[source_path]
        new(site, source_path, relative_source_path, options = {})
      end

      def s_to_class(s, start = self)
        s.split('::').map(&:to_sym).inject(self) do |p,c|
          return nil unless p.const_defined?(c)
          p.const_get(c)
        end
      end
    end # class << self

    def initialize(site, source_path, relative_source_path, options = {})
      super({})
      @raw_page_content     = ''
      @content_start_line   = 1
      @site                 = site
      self.source_path          = source_path
      self.relative_source_path = relative_source_path
      load_page
      Tilt.new(source_path, @content_start_line) do |template|
        @template       = template
        @template_type  = template.class.to_s.split('Tilt::',2)[-1]
        (mixin = self.class.s_to_class(@template_type)) && extend(mixin)
        template.options.merge!(opts.merge(user_rules))
        @raw_page_content
      end # template
      unless ( relative_source_path.nil? )
        dir_name         = File.dirname( relative_source_path )
        self.output_path = dir_name == "." ? output_filename : File.join( dir_name, output_filename )
      end
    end

    def render(context, locals = {}, &blk)
      @template.render(context, locals, &blk)
    end

    def content
      render(site.engine.create_context(self))
    end

    def output_filename
      # @todo use Tilt.mappings
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


  protected

    # Retreive the source file, extract the YAML and return the raw template content.
    # @return [String]
    def load_page
      full_content      = File.binread(self.source_path)
      full_content.force_encoding(@site.encoding) if @site.encoding && full_content.encoding != @site.encoding
      yaml_content      = []
      @raw_page_content = []

      begin
        lines = full_content.each_line
        if lines.peek.strip == '---'
          lines.next
          yaml_content << lines.next while lines.peek.strip != '---'
          lines.next
          yaml_content = yaml_content
        end # line.peek.strip == '---'
        @raw_page_content << lines.next while true
      rescue StopIteration # we're done
      rescue Exception => e
        e.set_backtrace(e.backtrace.unshift("#{source_path}:#{@header_line_cnt + @raw_page_content.count}"))
        raise e
      ensure
        @header_line_cnt    = yaml_content.count + 2
        @content_start_line = lines.count - @raw_page_content.count + 1
        @raw_page_content   = @raw_page_content.join
      end

      begin
        @front_matter = YAML.load( yaml_content.join ) || {}
        @front_matter.each { |k,v| self.send( "#{k}=", v ) }
      rescue => e
        puts "error reading #{self}: #{e}"
      end

      @raw_page_content
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
  end
end
