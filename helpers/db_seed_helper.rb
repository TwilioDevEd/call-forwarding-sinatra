require 'fileutils'
require 'pg'
require 'csv'
require 'json'

module DbSeedHelper
  def self.parse_and_store_zipcodes(file_name, pg_conn)
    values = []
    CSV.foreach(file_name).with_index(1) do |row, line|
      if line > 1
        values << "(#{row[0]}, '#{row[3]}')"
      end
      if values.size > 50
        values_string = values.reject(&:empty?).join(',')
        pg_conn.exec "INSERT INTO zipcodes (zipcode, state) VALUES #{values_string}"
        values = []
      end
    end
  end

  def self.parse_and_store_senators_and_states(filename, pg_conn)
    senators_json = JSON.parse(File.read(filename))
    state_list = senators_json['states']
    state_list.each do |state|
      result = pg_conn.exec "INSERT INTO states (name) VALUES ('#{state}') RETURNING id"
      state_id = result[0]['id']
      senators_json[state].each do |senator|
        pg_conn.exec "INSERT INTO senators (state_id, name, phone) VALUES (#{state_id}, '#{senator['name']}', '#{senator['phone']}')"
      end if senators_json[state]
    end
  end
end
