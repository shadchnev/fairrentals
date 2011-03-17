
# set sinatra's variables
set :app_file, __FILE__
set :root, File.dirname(__FILE__)
set :views, "views"
set :public, 'public2'

configure do
  
  # Configure public directory
  set :public, File.join(File.dirname(__FILE__), 'public')

  # Configure HAML and SASS
  set :haml, { :format => :html5 }
  set :sass, { :style => :compressed } if ENV['RACK_ENV'] == 'production'
  
  
end

# at a minimum, the main sass file must reside within the ./views directory. here, we create a ./views/stylesheets directory where all of the sass files can safely reside.
get '/stylesheets/:name.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :"stylesheets/#{params[:name]}"
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