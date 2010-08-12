$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "rubygems"
require "rails"
require "spec"
require "rr"

Spec::Runner.configure do |config|  
  config.mock_with RR::Adapters::Rspec
end