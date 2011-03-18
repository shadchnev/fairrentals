require 'bundler'
Bundler.require
require 'nestoria/api'

require './app'

use Rack::ShowExceptions

run Sinatra::Application