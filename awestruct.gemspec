require File.expand_path("../lib/awestruct/version", __FILE__)

Gem::Specification.new do |s|
    s.platform       =   Gem::Platform::RUBY
    s.name           =   "awestruct"
    s.version        =   Awestruct::VERSION
    s.author         =   "Bob McWhirter"
    s.email          =   "bob@mcwhirter.org"
    s.summary        =   "Static site-baking utility"
    s.files          =   Dir['lib/**/*.rb'] | Dir['lib/**/*.haml']
    s.executables    =   [ 'awestruct' ]
    s.require_paths  =   [ 'lib' ]
    s.has_rdoc       =   true

    s.add_dependency 'tilt'
    s.add_dependency 'haml', '<= 3.1.0'
    s.add_dependency 'sass', '<= 3.1.0'
    s.add_dependency 'redcarpet'
    s.add_dependency 'liquid'
    s.add_dependency 'org-ruby', '= 0.5.3'

    s.add_dependency 'nokogiri'

    s.add_dependency 'hashery', '= 1.4.0'
    s.add_dependency 'compass', '>= 0.11.5'
    s.add_dependency 'compass-960-plugin', '<= 0.10.4'
    s.add_dependency 'fssm', '= 0.2.7'
end

