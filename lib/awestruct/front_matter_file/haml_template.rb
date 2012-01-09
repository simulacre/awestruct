module Awestruct
  class FrontMatterFile < OpenStruct
    module HamlTemplate

      # Haml encoding exception backtraces are always off by 2,
      # so we intercept and correct them.
      # @todo update the correct line of the backtrace !
      def render(context, locals = {}, &blk)
        rendered = ""
        begin
          rendered = super
        rescue Encoding::CompatibilityError => e
          line = e.backtrace[0].split(":")[1].to_i + 2
          e.set_backtrace([".#{relative_source_path}:#{line}"].push(*e.backtrace[1..-1]))
          puts e
          puts e.backtrace
        rescue Exception => e
          puts e
          puts e.backtrace
        end
        rendered
      end

    end # module::HamlTemplate
  end # class::FrontMatterFile < OpenStruct
end # module::Awestruct
