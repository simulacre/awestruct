module Awestruct
  class FrontMatterFile < OpenStruct
    class Filter
      def initialize(&blk)
        instance_eval(&blk) if block_given?
      end # initialize(&blk)

      def pre_render(page = nil, &blk)
        return @prerender = blk if block_given?
        @prerender ? @prerender.call(page) : page.content
      end # pre_render(&blk)

      def post_render(page = nil, &blk)
        return @postrender = blk if block_given?
        @postrender ? @postrender.call(page) : page.content
      end # post_render(&blk)
    end # class::Filter
  end # class::FrontMatterFile < OpenStruct
end # module::Awestruct
