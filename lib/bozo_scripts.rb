$:.push File.expand_path(File.dirname(__FILE__))

require 'fileutils'
require 'rainbow'
require 'bozo'

require 'bozo/compilers/msbuild'
require 'bozo/dependency_resolvers/nuget'
require 'bozo/hooks/common_assembly_info'
require 'bozo/hooks/file_templating'
require 'bozo/hooks/fxcop'
require 'bozo/hooks/git_commit_hashes'
require 'bozo/hooks/git_tag_release'
require 'bozo/hooks/teamcity'
require 'bozo/hooks/timing'
require 'bozo/packagers/gem'
require 'bozo/packagers/nuget'
require 'bozo/publishers/file_copy'
require 'bozo/publishers/rubygems'
require 'bozo/test_runners/nunit'
require 'bozo/test_runners/runit'
require 'bozo/configuration'
require 'bozo/erubis_templating_coordinator'
require 'bozo/version'