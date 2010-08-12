Rails.application.routes.draw do |map|
  match "xss/:path" => "xss#load"
end