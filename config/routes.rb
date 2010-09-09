Rails.application.routes.draw do
  match "xss/:path" => "xss#load"
end
