require "xss/extensions/controller"
require "xss/extensions/view"
require "xss/extensions/string"

ActiveSupport.on_load(:action_controller) do
  include Vidibus::Xss::Extensions::Controller
end

String.send :include, Vidibus::Xss::Extensions::String