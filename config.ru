require 'bundler'
Bundler.require
require 'nestoria/api'

require './property'
require './app'

use Rack::ShowExceptions

run Sinatra::Application