$:.push File.expand_path(File.dirname(__FILE__))

require 'fileutils'
require 'rainbow'
require 'bozo/version'
require 'bozo/compilers/msbuild'
require 'bozo/dependency_resolvers/bundler'
require 'bozo/dependency_resolvers/nuget'
require 'bozo/hooks/common_assembly_info'
require 'bozo/publishers/nuget'
require 'bozo/test_runners/nunit'