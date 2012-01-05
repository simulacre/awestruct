module Awestruct
  class FrontMatterFile < OpenStruct
    module RedcarpetTemplate
      def opts
        {
          :fenced_code_blocks => true,
          :autolink           => true,
          :strikethrough      => true
        }
      end
    end # module::RedcarpetTemplate
  end # class::FrontMatterFile < OpenStruct
end # module::Awestruct
