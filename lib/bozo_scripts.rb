$:.push File.expand_path(File.dirname(__FILE__))

require 'fileutils'
require 'rainbow'
require 'bozo'

require 'bozo/compilers/msbuild'
require 'bozo/dependency_resolvers/bundler'
require 'bozo/dependency_resolvers/nuget'
require 'bozo/hooks/fxcop'
require 'bozo/hooks/git_commit_hashes'
require 'bozo/hooks/build_number_version'
require 'bozo/hooks/git_tag_release'
require 'bozo/hooks/git_hub'
require 'bozo/hooks/hipchat'
require 'bozo/hooks/jenkins'
require 'bozo/hooks/teamcity'
require 'bozo/hooks/timing'
require 'bozo/packagers/rubygems'
require 'bozo/packagers/nuget'
require 'bozo/preparers/common_assembly_info'
require 'bozo/preparers/file_templating'
require 'bozo/publishers/file_copy'
require 'bozo/publishers/nuget'
require 'bozo/publishers/rubygems'
require 'bozo/test_runners/dotcover'
require 'bozo/test_runners/opencover'
require 'bozo/test_runners/nunit'
require 'bozo/test_runners/runit'
require 'bozo/configuration'
require 'bozo/erubis_templating_coordinator'
require 'bozo/version'
require 'bozo/tools/nuget'
