class XssController < ApplicationController
  unloadable
  
  def load
    custom_params = params.except(:path, :scope, :controller, :action)
    path = params[:path]
    path += "?#{custom_params.to_uri}" if custom_params.any?
    render :path => path, :format => :xss
  end
end