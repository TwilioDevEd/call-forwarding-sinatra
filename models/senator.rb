require 'data_mapper'

class Senator
  include DataMapper::Resource

  property :id, Serial
  property :name, String, length: 255
  property :phone, String

  belongs_to :state
end
