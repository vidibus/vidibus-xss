class XssController < ApplicationController
  unloadable
  
  def load
    render :path => params[:path], :format => :xss
  end
end