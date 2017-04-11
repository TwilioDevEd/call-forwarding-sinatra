require 'sinatra'

module CallForwarding
  class App < Sinatra::Base
    set :show_exceptions, false
    set :raise_errors, false
    set :root, File.dirname(__FILE__)

    # home
    get '/' do
      erb :index
    end
  end
end
