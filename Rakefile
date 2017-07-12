require 'rspec/core/rake_task'
require 'fileutils'
require 'pg'
require 'ostruct'
require 'yaml'
require_relative './helpers/db_seed_helper'

RSpec::Core::RakeTask.new(:spec)

db_names = ['call_forwarding', 'call_forwarding_test']

CONFIG = OpenStruct.new(YAML.load_file("config/app.yml"))
namespace :db do
  task :create, [:username] do |_, args|
    desc 'generate application database'
    db_names.each do |db_name|
      sh "psql -c 'create database #{db_name};' -U #{args[:username]}" do |ok,res|
        #empty block to ignore any failed or success status
      end
      begin
        conn = PG::Connection.open(:dbname => db_name)
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
end

namespace :db do
  task :seed do |_, args|
    desc 'Seed application database'
    puts "********Seeding Data Start************"
    CONFIG.to_h.each do |k, env|
      begin
        conn = PG::Connection.open(:dbname => env['database_name'])
        DbSeedHelper.parse_and_store_zipcodes("#{env['seed_folder']}/free-zipcode-database.csv", conn)
        DbSeedHelper.parse_and_store_senators_and_states("#{env['seed_folder']}/senators.json", conn)
      rescue PG::Error => e
        puts e.message
      ensure
        conn.close if conn
      end
    end
  end
end

task default: :spec
