set :root, File.dirname(__FILE__)

configure do
  require 'sass/plugin/rack'
  use Sass::Plugin::Rack
end

configure :production do
  set :sass, { :style => :compressed }
end

get '/' do
  haml :index
end

post '/similar-properties' do
  rentals = Zoopla.new('ghj3ebxfkb6q6ndudww6crrc').rentals
  price = params[:price].to_i rescue 0
  return 'meh' unless price > 0
  prices = []
  # price_range = (price*0.9).round..(price*1.1).round
  rentals.flats.in({:postcode => params[:postcode]}).beds(params[:beds].to_i).within(0.2).each{|listing|
    prices << listing.price if listing.price
  }
  @average = prices.size ? prices.inject(0) {|sum, price| sum += price} / prices.size : "unknown"
  @difference = ((@average / price.to_f - 1) * 100).round
  haml :similar_properties, :layout => false
end