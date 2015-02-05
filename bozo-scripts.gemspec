# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "bozo/version"

Gem::Specification.new do |s|
  s.name        = "bozo-scripts"
  s.version     = BozoScripts::VERSION
  s.authors     = ["Garry Shutler", "Luke Smith"]
  s.email       = ["garryshutler@zopa.com", "luke@zopa.com"]
  s.homepage    = "https://github.com/zopaUK/bozo-scripts"
  s.platform    = Gem::Platform::RUBY
  s.summary     = "Zopa build system scripts"
  s.description = "Zopa build system scripts"

  s.rubyforge_project = "bozo-scripts"

  s.files         = Dir['lib/**/*'] + Dir['VERSION'] + Dir['LICENSE']
  s.test_files    = Dir['test/**/*'] + Dir['spec/**/*'] + Dir['features/**/*']
  s.executables   = []
  s.require_paths = ['lib']

  s.add_runtime_dependency "nokogiri", '~> 1.5.1'
  s.add_runtime_dependency "erubis", '~> 2.7.0'
  s.add_runtime_dependency 'test-unit', '~> 2.4.8'
  s.add_runtime_dependency "bozo", '~> 0.4.0'
  s.add_runtime_dependency "zip", '~> 2.0.2'
end
