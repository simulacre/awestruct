module Awestruct

  module Hamlable
    def render(context)
      rendered = ''
      begin
        options = (site.haml || {}).inject({}){|h,(k,v)| h[k.to_sym] = v.to_sym; h }
        haml_engine = Haml::Engine.new( raw_page_content, options )
        rendered = haml_engine.render( context )
      rescue => e
        lineo = e.backtrace[0].split(":")[1]
        e.set_backtrace(e.backtrace[1..-1].unshift("#{self.source_path}:#{lineo}"))
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
