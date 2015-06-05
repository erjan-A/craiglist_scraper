namespace :scraper do
  desc "Fetch Craiglist posts from 3taps"
  task scrape: :environment do
  	require 'open-uri'
  	require 'json'
  	# Set API token and URL
  	auth_token = '064406ac49cde3258fd8ec17d5f077ee'
  	polling_url = "http://polling.3taps.com/poll"

    # Grab data until up-to-date
    loop do

    	#Specify request parameters
    	params = {
    		auth_token: auth_token,
    		anchor: Anchor.first.value,
    		source: "CRAIG",
    		category_group: "RRRR",
    		category: "RHFR",
    		'location.city' => "USA-NYM-BRL",
    		retvals: "location,external_url,heading,body,timestamp,price,images,annotations"
    	}

    	# Prepare API request
    	uri = URI.parse(polling_url)
    	uri.query = URI.encode_www_form(params)

    	# Submit request
    	result = JSON.parse(open(uri).read)

      # puts result["postings"].first["annotations"]["bedrooms"]
      # puts JSON.pretty_generate result["postings"].second["annotations"]

    	# Store results in database
      result["postings"].each do |posting|
        # Create new post
        @post = Post.new
        @post.heading = posting["heading"]
        @post.body = posting["body"]
        @post.price = posting["price"]
        @post.neighborhood = Location.find_by(code: posting["location"]["locality"]).try(:name)
        @post.external_url = posting["external_url"]
        @post.timestamp = posting["timestamp"]
        @post.bedrooms = posting["annotations"]["bedrooms"]
        @post.bathroom = posting["annotations"]["bathrooms"]
        @post.sqft = posting["annotations"]["sqft"]
        @post.cats = posting["annotations"]["cats"]
        @post.dogs = posting["annotations"]["dogs"]
        @post.w_d_in_unit = posting["annotations"]["w_d_in_unit"]
        @post.street_parking = posting["annotations"]["street_parking"]

        @post.save

        # Loop over images and save to Image database
        posting["images"].each do |image|
          @image = Image.new
          @image.url = image["full"]
          @image.post_id = @post.id
          @image.save
        end
      end

      Anchor.first.update(value: result["anchor"])
      puts Anchor.first.value
      break if result["postings"].empty?
    end
end

  desc "Destroy all posting data"
  task destroy_all_posts: :environment do
    Post.destroy_all
  end

  desc "Save neighborhood codes in a reference table"
  task scrape_neighborhoods: :environment do
    require 'open-uri'
    require 'json'
    # Set API token and URL
    auth_token = '064406ac49cde3258fd8ec17d5f077ee'
    location_url = "http://reference.3taps.com/locations"

    #Specify request parameters
    params = {
        auth_token: auth_token,
        level: "locality",
        city: "USA-NYM-BRL"
    }

    # Prepare API request
    uri = URI.parse(location_url)
    uri.query = URI.encode_www_form(params)

    # Submit request
    result = JSON.parse(open(uri).read)

    # puts result["postings"].first["annotations"]["bedrooms"]
    # puts JSON.pretty_generate result["postings"].second["annotations"]

    # Store results in DB
    result["locations"].each do |location|
        @location = Location.new
        @location.code = location["code"]
        @location.name = location["short_name"]
        @location.save
    end
  end

end
