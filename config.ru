require 'bundler/setup'
Bundler.require

require 'sinatra'
require 'sinatra/json'
require 'sequel'
require 'json'
require 'rack/cors'

DB = Sequel.connect('sqlite://db/equipment.db')
DB.extension :date_arithmetic

Dir[File.join(File.dirname(__FILE__), 'models', '*.rb')].each { |f| require f }
Dir[File.join(File.dirname(__FILE__), 'helpers', '*.rb')].each { |f| require f }
Dir[File.join(File.dirname(__FILE__), 'routes', '*.rb')].each { |f| require f }

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :put, :delete, :options]
  end
end

class EquipmentBorrowAPI < Sinatra::Base
  helpers AuthHelper

  set :json_encoder, :to_json
  set :show_exceptions, false
  set :raise_errors, false

  before do
    content_type :json
  end

  error do |e|
    status 500
    { error: '服务器内部错误', message: e.message }.to_json
  end

  error 404 do
    { error: '资源不存在' }.to_json
  end

  get '/api/health' do
    { status: 'ok', timestamp: Time.now }.to_json
  end

  register UsersRoutes
  register DevicesRoutes
  register BorrowsRoutes
end

run EquipmentBorrowAPI
