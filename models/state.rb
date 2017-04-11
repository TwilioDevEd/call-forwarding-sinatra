require 'data_mapper'

class State
  include DataMapper::Resource

  property :id, Serial
  property :name, String, length: 255

  has n, :senators
end
