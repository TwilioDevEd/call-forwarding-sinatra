require 'data_mapper'


class State
  include DataMapper::Resource

  property :id, Serial
  property :name, String, length: 255

  has n, :senators

  def self.get_senators(state)
    Senator.all(Senator.state.name => state)
  end

end
