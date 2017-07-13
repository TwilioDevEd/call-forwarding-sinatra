require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/multi_route'
require_relative './helpers/datamapper_helper'

ENV['RACK_ENV'] ||= 'development'
require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

module CallForwarding
  class App < Sinatra::Base
    set :show_exceptions, false
    set :raise_errors, false
    set :root, File.dirname(__FILE__)

    register Sinatra::MultiRoute
    register Sinatra::ConfigFile
    config_file 'config/app.yml'

    DataMapperHelper.setup(settings.database_url)
    DataMapperHelper.seed_if_empty(settings.seed_folder)

    # home
    get '/' do
      erb :index
    end

    post '/callcongress/welcome' do
      # Verify or collect State information
      from_state = params['FromState']

      content_type 'text/xml'
      response = Twilio::TwiML::VoiceResponse.new
      if from_state
        response.say("Thank you for calling congress! It looks like
                you\'re calling from #{from_state}.
                If this is correct, please press 1. Press 2 if
                this is not your current state of residence.")
        response.gather(numDigits: 1,
                        action: '/callcongress/set-state',
                        method: 'POST',
                        from_state: from_state)
      else
        response.say("Thank you for calling Call Congress! If you wish to
                call your senators, please enter your 5-digit zip code.")
        response.gather(numDigits: 5,
                        action: '/callcongress/state-lookup',
                        method: 'POST')
      end

      response.to_s
    end

    route :get, :post, '/callcongress/state-lookup' do
      # Look up state from given zipcode.
      # Once state is found, redirect to call_senators for forwarding.
      zip_digits = params['Digits']
      # NB: We don't do any error handling for a missing/erroneous zip code
      # in this sample application. You, gentle reader, should handle that
      # edge case before deploying this code.
      zip_obj = Zipcode.first(zipcode: zip_digits)

      call_senators(zip_obj.state)
    end

    route :get, :post, '/callcongress/set-state' do
      # Set state for senator call list.
      # Set user's state from confirmation or user-provided Zip.
      # Redirect to call_senators route.

      # Get the digit pressed by the user
      digits_provided = params['Digits']

      # Set state if State correct, else prompt for zipcode.
      if digits_provided == '1'
        state = params['FromState']
        call_senators(state)
      elsif digits_provided == '2'
        collect_zip
      end
    end

    route :get, :post, '/callcongress/call-second-senator/:senator_id' do
      # Forward the caller to their second senator.
      senator = Senator.get(params['senator_id'])

      content_type 'text/xml'
      response = Twilio::TwiML::VoiceResponse.new
      response.say "Connecting you to #{senator.name}"
      response.dial(number: senator.phone, action: '/callcongress/goodbye')
      response.to_s
    end

    route :get, :post, '/callcongress/goodbye' do
      # Thank user & hang up.
      content_type 'text/xml'
      response = Twilio::TwiML::VoiceResponse.new
      response.say("Thank you for using Call Congress!
               Your voice makes a difference. Goodbye.")
      response.hangup
      response.to_s
    end

    def collect_zip
      # Prompt user for zip code.
      content_type 'text/xml'
      response = Twilio::TwiML::VoiceResponse.new
      response.say "If you wish to call your senators, please
              enter your 5-digit zip code."
      response.gather(numDigits: 5,
                      action: '/callcongress/state-lookup',
                      method: 'POST')

      response.to_s
    end

    def call_senators(state)
      # Method connecting caller to both of their senators.
      senators = State.get_senators(state)

      content_type 'text/xml'
      first_call = senators[0]
      second_call = senators[1]
      response = Twilio::TwiML::VoiceResponse.new
      response.say("Connecting you to #{first_call.name}. "\
          "After the senator's office ends the call, you will "\
          "be re-directed to #{second_call.name}")
      response.dial(number: first_call.phone,
                    action: "/callcongress/call-second-senator/#{second_call.id}")
      response.to_s
    end
  end
end
