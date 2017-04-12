require 'sinatra/base'
require 'sinatra/config_file'
require_relative './helpers/datamapper_helper'
require_relative './lib/twiml_generator'

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

    post '/callcongress/welcome' do
      # Verify or collect State information
      from_state = params['FromState']

      if(from_state)
        twiml = TwimlGenerator.confirm_from_state_attribute_is_correct(from_state)
      else
        twiml = TwimlGenerator.gather_zipcode_and_look_it_up(
          "Thank you for calling Call Congress! If you wish to
          call your senators, please enter your 5-digit zip code.")
      end
      content_type 'text/xml'
      twiml
    end

    post '/callcongress/state-lookup' do
      # Look up state from given zipcode.
      # Once state is found, redirect to call_senators for forwarding.
      zip_digits = params['Digits']
      # NB: We don't do any error handling for a missing/erroneous zip code
      # in this sample application. You, gentle reader, should handle that
      # edge case before deploying this code.
      zip_obj = Zipcode.first(zipcode=>zip_digits)

      call_senators(zip_obj.state_id)
    end

    post '/callcongress/set-state' do
      # Set state for senator call list.
      # Set user's state from confirmation or user-provided Zip.
      # Redirect to call_senators route.

      # Get the digit pressed by the user
      digits_provided = params('Digits')

      # Set state if State correct, else prompt for zipcode.
      if digits_provided == '1'
          state = params('CallerState')
          state_obj = State.first(:name => state)
          call_senators(state_obj.id)
      else digits_provided == '2'
          collect_zip
      end
    end

    post '/callcongress/call-second-senator/:senator_id' do
      # Forward the caller to their second senator.
      senator = Senator.get(params['senator_id'])

      content_type 'text/xml'
      TwimlGenerator.dial_second_senator(senator)
    end

    post '/callcongress/goodbye' do
      # Thank user & hang up.
      content_type 'text/xml'
      TwimlGenerator.hangup_call
    end

    def collect_zip()
      # If our state guess is wrong, prompt user for zip code.
      content_type 'text/xml'
      twiml = TwimlGenerator.gather_zipcode_and_look_it_up(
        "If you wish to call your senators, please
        enter your 5-digit zip code.")
    end

    def call_senators(state_id)
      # Function connecting caller to both of their senators.
      senators = State.get_senators(state_id)

      content_type 'text/xml'
      TwimlGenerator.dial_first_senator_then_connect_second(senators[0], senators[1])
    end
  end
end
