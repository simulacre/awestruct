require 'awestruct/renderable_file'

module Awestruct
  class FrontMatterFile < RenderableFile

    attr_reader :raw_page_content
    attr_reader :front_matter

    def initialize(site, source_path, relative_source_path, options = {})
      super( site, source_path, relative_source_path, options )
      @raw_page_content = ''
      @header_line_cnt  = 1
      load_page
    end

    protected

    def load_page
      full_content = File.read( source_path )
      full_content.force_encoding(@site.encoding) if @site.encoding
      yaml_content      = []
      @raw_page_content = []

      begin
        lines = full_content.each_line
        if lines.peek.strip == '---'
          lines.next
          yaml_content << lines.next while lines.peek.strip != '---'
          lines.next
          @header_line_cnt = yaml_content.count + 3
          yaml_content = yaml_content
        end # line.peek.strip == '---'
        @raw_page_content << lines.next while true

      rescue StopIteration # we're done
      rescue Exception => e
        e.set_backtrace(e.backtrace.unshift("#{source_path}:#{@header_line_cnt + @raw_page_content.count}"))
        raise e
      ensure
        @raw_page_content = @raw_page_content.join
      end

      begin
        @front_matter = YAML.load( yaml_content.join ) || {}
        @front_matter.each do |k,v|
          self.send( "#{k}=", v )
        end
      rescue => e
        puts "error reading #{self}: #{e}"
      end
    end
  end
end
