require 'data_mapper'

require_relative './state'

class Zipcode
  include DataMapper::Resource

  property :id, Serial
  property :zipcode, Integer
  property :state, String, length: 4

  def self.state_id
    State.first(:name => :state)
  end
end
