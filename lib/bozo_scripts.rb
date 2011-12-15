$:.push File.expand_path(File.dirname(__FILE__))

require 'fileutils'
require 'rainbow'
require 'bozo/compilers/msbuild'
require 'bozo/dependency_resolvers/bundler'
require 'bozo/dependency_resolvers/nuget'
require 'bozo/publishers/nuget'
require 'bozo/test_runners/nunit'

module BozoScripts

  VERSION = '0.1.0'
  
end