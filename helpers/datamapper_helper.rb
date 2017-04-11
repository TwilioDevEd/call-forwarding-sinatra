require 'data_mapper'
require 'pg'

require_relative './db_seed_helper'
require_relative '../models/senator'
require_relative '../models/state'
require_relative '../models/zipcode'

module DataMapperHelper
  def self.setup(database_url)
    DataMapper.setup(:default, database_url)
    DataMapper.finalize

    # this section automatically creates the tables
    Zipcode.auto_upgrade!
    State.auto_upgrade!
    Senator.auto_upgrade!
  end

  def self.seed_if_empty
    begin
      conn = PG::Connection.open(:dbname => 'call_forwarding')
      if Zipcode.all.count == 0
        puts 'Seeding Zipcodes table'
        DbSeedHelper.parse_and_store_zipcodes('free-zipcode-database.csv', conn)
      end
      if State.all.count == 0
        puts 'Seeding Senators and States tables'
        DbSeedHelper.parse_and_store_senators_and_states('senators.json', conn)
      end
    rescue PG::Error => e
      puts e.message
    ensure
      conn.close if conn
    end
  end
end
