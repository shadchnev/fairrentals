class Property
  
  MAX_PROPERTIES = 5
  EURO_TO_POUND = 1.14
  WEEKS_IN_A_MONTH = 4.33
  PLACEHOLDERS = [
    'http://1.s.fr.nestoria.nestimg.com/i/all/all/all/g/cs3.2.png',
    'http://2.l.it.nestoria.nestimg.com/1vd/0/6/1vd064a5ead9ec7c53fc6e49d39eaa83d5d86a795f.2.jpg',
    'http://3.s.es.nestoria.nestimg.com/i/all/all/all/g/cs3.2.png'  
    ]
  
  CAPITALS = {
    :de => {:city => "Berlin", :search_term => "Berlin"},
    :it => {:city => "Rome", :search_term => "Roma"},
    :es => {:city => "Madrid", :search_term => "Madrid"},
    :fr => {:city => "Paris", :search_term => "Paris"}
  }
  
  def self.nestoria_query(region, price, beds)
    room_type = [:uk, :es].include?(region) ? "bedroom" : 'room' # in uk and es we use bedrooms, unlike the rest of the world
    beds += 1 # you'll get nicer flats?
    size = {"#{room_type}_min".to_sym => beds, "#{room_type}_max".to_sym => beds}
    price = price * EURO_TO_POUND * WEEKS_IN_A_MONTH
    price_min = (price * 0.9).round
    price_max = (price * 1.1).round
    {:property_type => 'flat', 
     :listing_type => 'rent', 
     :place_name => CAPITALS[region][:search_term],
     :price_min => price_min,
     :price_max => price_max,
     :has_photo => '1'
    }.merge!(size)
  end
  
  def self.listings(region, price, beds)
    results = Nestoria::Api.new(region).search(nestoria_query(region, price, beds))
    raise "Bad reply from Nestoria: #{results["application_response_code"]}" unless (100..110).include?(results["application_response_code"].to_i)
    all_properties = results["listings"].inject([]) do |all, listing|
      if listing["price_type"] == "monthly" and !PLACEHOLDERS.include?(listing["img_url"])
        all << {:price => (listing["price"].to_i / EURO_TO_POUND / WEEKS_IN_A_MONTH).round, :image => listing["img_url"], :url => listing["lister_url"], :size => listing["room_number"] || listing["bedroom_number"]}    
      end
      all
    end
    return all_properties if all_properties.length <= MAX_PROPERTIES
    properties = []
    MAX_PROPERTIES.times do |i|
      properties << all_properties.slice!(rand(all_properties.length), 1).first
    end
    properties
  end
  
  def self.average_price(postcode, beds)
    cache_key = "#{postcode.gsub(/[^a-z0-9\-_]+/i, '')}-#{beds}-prices"
    prices = latest_prices(postcode, beds, cache_key) unless prices = CACHE.get(cache_key)
    prices.size > 0 ? prices.inject(0) {|sum, price| sum += price} / prices.size : nil
  end
  
  def self.latest_prices(postcode, beds, cache_key)
    rentals = Zoopla.new(ENV['ZOOPLA_KEY']).rentals
    prices = []
    rentals = rentals.flats.in({:postcode => postcode}).include_rented.within(0.2)
    rentals = rentals.beds(beds) if beds > 0 # it looks like zoopla doesn't understand 0 in here
    rentals.each{|listing|
      studio = listing.description =~ /bedsit|studio/i
      next if ((beds == 1) and studio) || (beds != listing.num_bedrooms)
      prices << listing.price if listing.price
    }
    CACHE.set(cache_key, prices)
    prices    
  end
  
end