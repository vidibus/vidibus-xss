class XssController < ApplicationController
  unloadable

  def load
    custom_params = params.symbolize_keys.except(:path, :scope, :controller, :action)
    path = params[:path]
    path += "?#{custom_params.to_uri}" if custom_params.any?
    render :path => path, :format => :xss
  end
end
