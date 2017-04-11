require 'sinatra/base'
require 'sinatra/config_file'


require_relative './helpers/datamapper_helper'

ENV['RACK_ENV'] ||= 'development'
require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

module CallForwarding
  class App < Sinatra::Base
    set :show_exceptions, false
    set :raise_errors, false
    set :root, File.dirname(__FILE__)

    register Sinatra::ConfigFile
    config_file 'config/app.yml'

    DataMapperHelper.setup(settings.database_url)
    DataMapperHelper.seed_if_empty

    # home
    get '/' do
      erb :index
    end

  end
end
