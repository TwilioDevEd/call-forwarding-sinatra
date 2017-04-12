require 'rspec/core/rake_task'
require 'fileutils'
require 'pg'
require_relative './helpers/db_seed_helper'

RSpec::Core::RakeTask.new(:spec)

namespace :db do
  task :create, [:username] do |_, args|
    desc 'generate application database'
    sh "psql -c 'create database call_forwarding;' -U #{args[:username]}" do |ok,res|
      #empty block to ignore any failed or success status
    end
    sh "psql -c 'create database call_forwarding_test;' -U #{args[:username]}" do |ok,res|
      #empty block to ignore any failed or success status
    end

    begin
      conn = PG::Connection.open(:dbname => 'call_forwarding')
      conn.exec "create table states (id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL)"
      conn.exec "create table zipcodes (id SERIAL PRIMARY KEY,
        zipcode INTEGER NOT NULL, state VARCHAR(100) NOT NULL)"
      conn.exec "create table senators (id SERIAL PRIMARY KEY,
        state_id INTEGER REFERENCES states(id) NULL,
        name VARCHAR(100) NOT NULL, PHONE VARCHAR(100) NOT NULL)"
    rescue PG::Error => e
      puts e.message
    ensure
      conn.close if conn
    end
  end
end

namespace :db do
  task :seed do |_, args|
    desc 'Seed application database'
    puts "********Seeding Data Start************"
    begin
      conn = PG::Connection.open(:dbname => 'call_forwarding')
      DbSeedHelper.parse_and_store_zipcodes('free-zipcode-database.csv', conn)
      DbSeedHelper.parse_and_store_senators_and_states('senators.json', conn)
    rescue PG::Error => e
      puts e.message
    ensure
      conn.close if conn
    end
  end
end

task default: :spec
