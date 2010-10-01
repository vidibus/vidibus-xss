$:.unshift(File.join(File.dirname(__FILE__), "..", "lib", "vidibus"))
require "xss"

module Vidibus::Xss
  class Engine < ::Rails::Engine; end
end
