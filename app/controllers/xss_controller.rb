class XssController < ApplicationController
  unloadable
  
  def load
    raise 'load'
  end
end