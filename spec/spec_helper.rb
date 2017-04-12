ENV['RACK_ENV'] = 'test'

require 'database_cleaner'
require_relative '../app'
require_relative '../helpers/datamapper_helper'

RSpec.configure do |config|
  include Rack::Test::Methods

  def app
    CallForwarding::App
  end

  config.formatter = :documentation
  config.before(:each) do
    DatabaseCleaner.start
  end

  config.append_after(:each) do
    DatabaseCleaner.clean
  end
end
