set :root, File.dirname(__FILE__)

configure do
  require 'sass/plugin/rack'
  use Sass::Plugin::Rack
  CACHE = Dalli::Client.new(nil, :expires_in => 1.day)
  Mongoid.configure do |config|
    if ENV['MONGOHQ_URL']
      conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
      uri = URI.parse(ENV['MONGOHQ_URL'])
      config.master = conn.db(uri.path.gsub(/^\//, ''))
    else
      config.master = Mongo::Connection.from_uri("mongodb://localhost:27017").db('fairrentals')
    end
  end
end

configure :production do
  set :sass, { :style => :compressed }
end

get '/' do
  haml :index
end

post '/similar-properties' do
  price = params[:price].to_i rescue 0
  beds = params[:beds].to_i rescue 0
  postcode = params[:postcode] if params[:postcode] =~ /^([A-PR-UWYZ0-9][A-HK-Y0-9][AEHMNPRTVXY0-9]?[ABEHMNPRVWXY0-9]? {1,2}[0-9][ABD-HJLN-UW-Z]{2}|GIR 0AA)$/i
  raise 'Params are invalid' unless price > 0 and postcode and beds >= 0
  
  Search.create(:postcode => postcode, :beds => beds, :price => price)  
  @average = Property.average_price(postcode, beds)
  @difference = ((price.to_f / @average  - 1) * 100).round if @average
  
  haml :similar_properties, :layout => false
end

post '/abroad' do
  region = params[:region].to_sym
  price = params[:price].to_i rescue 0
  beds = params[:beds].to_i rescue 0
  raise 'Params are invalid' unless price > 0 and beds >= 0
  @properties = Property.listings(region, price, beds)
  @city = Property::CAPITALS[region][:city]  
  haml :abroad, :layout => false
end

class Search
  include Mongoid::Document
  include Mongoid::Timestamps

  field :postcode
  field :price, :type => Integer
  field :beds, :type => Integer
end