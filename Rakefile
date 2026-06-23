require 'sequel'
require 'sequel/extensions/migration'

namespace :db do
  desc 'Run database migrations'
  task :migrate do
    DB = Sequel.connect('sqlite://db/equipment.db')
    Sequel::Migrator.run(DB, 'db/migrations')
    puts 'Migrations completed successfully'
  end

  desc 'Create database'
  task :create do
    Sequel.connect('sqlite://db/equipment.db')
    puts 'Database created successfully'
  end

  desc 'Drop database'
  task :drop do
    require 'fileutils'
    FileUtils.rm_f('db/equipment.db')
    puts 'Database dropped successfully'
  end

  desc 'Reset database'
  task reset: [:drop, :create, :migrate] do
    puts 'Database reset completed'
  end
end
