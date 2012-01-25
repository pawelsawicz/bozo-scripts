# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "bozo/version"

Gem::Specification.new do |s|
  s.name        = "bozo-scripts"
  s.version     = BozoScripts::VERSION
  s.authors     = ["Garry Shutler", "Luke Smith"]
  s.email       = ["garryshutler@zopa.com", "luke@zopa.com"]
  s.homepage    = ""
  s.summary     = "Zopa build system scripts"
  s.description = "Zopa build system scripts"

  s.files         = `git ls-files -- {*/**/*}`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "nokogiri"
  s.add_runtime_dependency "erubis"
  s.add_runtime_dependency "test-unit"
end
