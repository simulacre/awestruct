
module Awestruct
  module Extensions
    module Partial

      def partial(path, locals = {})
        page = site.engine.load_site_page( File.join( '_partials', path ) )
        locals.each { |name, value| page.send("#{name}=", value) }
        page.content if ( page )
      end

    end
  end

end
