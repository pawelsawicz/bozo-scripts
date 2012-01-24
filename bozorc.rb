require 'bozo_scripts'

version '0.1.0'

test_with :runit do |n|
  n.path 'test/**'
end

package_with :gem

with_hook :teamcity