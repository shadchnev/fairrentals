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
  raise 'Price is not valid' unless price > 0
  Search.create(:postcode => params[:postcode], :beds => params[:beds], :price => params[:price])
  cache_key = "#{params[:postcode].gsub!(/[^a-z0-9\-_]+/, '')}-#{params[:beds].to_i}-prices"
  if prices = CACHE.get(cache_key)
  else
    rentals = Zoopla.new('ghj3ebxfkb6q6ndudww6crrc').rentals
    prices = []
    beds = params[:beds].to_i
    rentals = rentals.flats.in({:postcode => params[:postcode]}).include_rented.within(0.2)
    rentals = rentals.beds(beds) if beds > 0 # it looks like zoopla doesn't understand 0 in here
    rentals.each{|listing|
      puts "#{listing.price} - #{listing.num_bedrooms} beds - #{listing.details_url}"
      studio = listing.description =~ /bedsit|studio/i
      next if ((beds == 1) and studio) || (beds != listing.num_bedrooms)
      prices << listing.price if listing.price
    }
    CACHE.set(cache_key, prices)
  end
  @average = prices.size ? prices.inject(0) {|sum, price| sum += price} / prices.size : "unknown"
  @difference = ((@average / price.to_f - 1) * 100).round
  haml :similar_properties, :layout => false
end

post '/abroad' do
  max_properties = 5
  euro_to_pound = 1.14
  weeks_in_a_month = 4.33
  region = params[:region].to_sym
  capitals = {
    :de => {:city => "Berlin", :search_term => "Berlin"},
    :it => {:city => "Rome", :search_term => "Roma"},
    :es => {:city => "Madrid", :search_term => "Madrid"},
    :fr => {:city => "Paris", :search_term => "Paris"}
  }
  @city = capitals[region][:city]
  room_type = [:uk, :es].include?(region) ? "bedroom" : 'room' # in uk and es we use bedrooms, unlike the rest of the world
  beds = params[:beds].to_i + 1 # you'll get nicer photos, probably
  size = {"#{room_type}_min".to_sym => beds, "#{room_type}_max".to_sym => beds}
  price = params[:price].to_i * euro_to_pound * 4.33 # weeks in a month
  price_min = (price * 0.9).round
  price_max = (price * 1.1).round
  query = {:property_type => 'flat', 
           :listing_type => 'rent', 
           :place_name => capitals[region][:search_term],
           :price_min => price_min,
           :price_max => price_max,
           :has_photo => '1'
          }.merge!(size)
  puts query
  results = Nestoria::Api.new(region).search(query)
  code = results["application_response_code"].to_i
  all_properties = []
  raise "Bad reply from Nestoria: #{code}" unless (100..110).include?(code)
  results["listings"].each do |listing|
    next unless listing["price_type"] == "monthly"
    all_properties << {:price => (listing["price"].to_i / euro_to_pound / weeks_in_a_month).round, :image => listing["img_url"], :url => listing["lister_url"], :size => listing["room_number"] || listing["bedroom_number"]}    
  end
  @properties = []
  if all_properties.length <= max_properties
    @properties = all_properties
  else
    max_properties.times do |i|
      @properties << all_properties.slice!(rand(all_properties.length), 1).first
    end
  end
  haml :abroad, :layout => false
end

class Search
  include Mongoid::Document
  include Mongoid::Timestamps

  field :postcode
  field :price, :type => Integer
  field :beds, :type => Integer
end