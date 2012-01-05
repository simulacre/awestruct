module Awestruct

  class VerbatimFile < OpenStruct
    attr_reader :site

    def initialize(site, source_path, relative_source_path)
      super({})
      @site                     = site
      self.source_path          = source_path
      self.relative_source_path = relative_source_path
      unless ( relative_source_path.nil? )
        dir_name         = File.dirname( relative_source_path )
        self.output_path = dir_name == "." ? output_filename : File.join( dir_name, output_filename )
      end
    end

    def raw_page_content
      #File.read( self.source_path ).tap {|f| f.force_encoding(@site.encoding) if @site.encoding }
      File.binread(self.source_path)
    end

    def render(context)
      raw_page_content
    end

    def output_extension
      File.extname(self.source_path)
    end

    def output_filename
      File.basename(self.source_path)
    end
  end
end
