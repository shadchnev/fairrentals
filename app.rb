set :root, File.dirname(__FILE__)

configure do
  require 'sass/plugin/rack'
  use Sass::Plugin::Rack
  CACHE = Dalli::Client.new(:expires_in => 1.day)
end

configure :production do
  set :sass, { :style => :compressed }
end

get '/' do
  haml :index
end

post '/similar-properties' do
  price = params[:price].to_i rescue 0
  return 'meh' unless price > 0
  cache_key = "#{params[:postcode].gsub!(/[^a-z0-9\-_]+/, '')}-#{params[:beds]}-prices"
  if prices = CACHE.get(cache_key)
  else
    rentals = Zoopla.new('ghj3ebxfkb6q6ndudww6crrc').rentals
    prices = []
    # price_range = (price*0.9).round..(price*1.1).round
    rentals.flats.in({:postcode => params[:postcode]}).beds(params[:beds].to_i).within(0.2).each{|listing|
      prices << listing.price if listing.price
    }
    CACHE.set(cache_key, prices)
  end
  @average = prices.size ? prices.inject(0) {|sum, price| sum += price} / prices.size : "unknown"
  @difference = ((@average / price.to_f - 1) * 100).round
  haml :similar_properties, :layout => false
end