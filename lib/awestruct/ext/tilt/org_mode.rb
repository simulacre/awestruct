module Tilt
  class OrgModeTemplate < Template
    self.default_mime_type = 'text/html'

    def self.engine_initialized?
      defined? ::Orgmode::Parser
    end

    def initialize_engine
      require_template_library 'org-ruby'
    end

    def prepare
      @engine = Orgmode::Parser.new(data)
    end

    def evaluate(scope, locals, &block)
      @output ||= @engine.to_html
    end
  end
  register OrgModeTemplate, 'org'
end


