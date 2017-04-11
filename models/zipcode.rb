require 'data_mapper'

class Zipcode
  include DataMapper::Resource

  property :id, Serial
  property :zipcode, Integer
  property :state, String, length: 4
end
