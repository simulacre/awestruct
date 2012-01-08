# Uses Brandon Tilly's GistTag Jekyll plugin, but sets the cache_folder
# to /tmp/awestruct/gist-cache instead of File.expand_path "../.gist-cache", File.dirname(__FILE__)
#
# Example usage: {% gist 1027674 gist_tag.rb %} //embeds a gist for this plugin

require "octopress/plugins/gist_tag"

module Awestruct
  class GistTag < ::Jekyll::GistTag
    def initialize(tag_name, text, token)
      self.class.superclass.superclass.instance_method(:initialize).bind(self).call(tag_name, text, token)
      @text           = text
      @cache_disabled = false
      @cache_folder   = '/tmp/awestruct/gist-cache'
      FileUtils.mkdir_p @cache_folder
    end # initialize(tag_name, text, token)
  end

  class GistTagNoCache < GistTag
    def initialize(tag_name, text, token)
      super
      @cache_disabled = true
    end
  end
end

Liquid::Template.register_tag('gist', Awestruct::GistTag)
Liquid::Template.register_tag('gistnocache', Awestruct::GistTagNoCache)
