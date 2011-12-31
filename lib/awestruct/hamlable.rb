module Awestruct

  module Hamlable
    def render(context)
      rendered = ''
      begin
        options = (site.haml || {}).inject({}){|h,(k,v)| h[k.to_sym] = v.to_sym; h }
        options[:filename] = ".#{relative_source_path}"
        options[:line] = (@header_line_cnt || 1)
        haml_engine = Haml::Engine.new( raw_page_content, options)
        rendered = haml_engine.render( context )
      rescue => e
        # normally we'd rely on passing :filename and :line as options to
        # Haml::Engine.new, but Haml checks for and raises encoding errors
        # before merging options, so they won't include the proper backtrace.
        if e.message =~ /^Invalid [\w\-]+ character/
          line = e.backtrace[0].split(":")[1].to_i + options[:line] - 2
          e.set_backtrace([".#{relative_source_path}:#{line}"].push(*e.backtrace[1..-1]))
        end
        puts e
        puts e.backtrace
      end
      rendered
    end

    def content
      context = site.engine.create_context( self )
      render( context )
    end
  end

end
