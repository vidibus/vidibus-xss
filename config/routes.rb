Rails.application.routes.draw do
  match "xss/:path" => "xss#load", :constraints => { :path => /.*/ }
end
