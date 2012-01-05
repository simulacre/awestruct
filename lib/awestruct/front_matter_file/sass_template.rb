module Awestruct
  class FrontMatterFile < OpenStruct
    module SassTemplate
      def opts
        Compass.sass_engine_options.tap do |opts|
          opts[:load_paths] ||= []
          Compass::Frameworks::ALL.each { |framework| opts[:load_paths].push(framework.stylesheets_directory) }
          opts[:load_paths] << File.dirname( self.source_path )
          opts[:syntax] = :sass
          opts[:custom] = self.site
          self.site.sass_rules.is_a?(Hash) && opts.merge!(self.site.sass_rules)
        end
      end
    end # module::SassTemplate

    module ScssTemplate
      include SassTemplate
      def opts
        super.merge(:syntax => :scss)
      end
    end # module::ScssTemplate

  end # class::FrontMatterFile < OpenStruct
end # module::Awestruct
