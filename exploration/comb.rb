require '../common.rb'

DB = Mongo::Connection.new.db('crunchbase_data')

people = DB.collection('person')

puts "We have #{people.size} in our Person's Database"
puts "Inspecting each person for web links (linkedin, facebook, etc)"

class Object
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end

URL_PATTERNS = {
	"twitter_url" => /twitter\.com/,
	"facebook_url" => /facebook\.com/,
	"linkedin_url" => /linkedin\.com\/in/
}

def extract_links_from_people( query )
	db = Mongo::Connection.new.db('crunchbase_data')
	people = db.collection("person")

	# peoples = people.find( { "$and" => [ query, { tag => { "$exists" => 0 } } ] } )
	peoples = people.find( query)

	puts "Tagging #{peoples.count} profiles"

	peoples.each do |person|

		urls_from_profile = []
		person["crunch_profile"].each do |profile|
			urls_from_profile << profile['homepage_url'] unless profile['homepage_url'].blank?
			profile["web_presences"].each do |hash|
				urls_from_profile << hash["external_url"] unless hash["external_url"].blank?
			end
		end

		urls = urls_from_profile.compact

		next if urls.empty?

		# have some urls, let's now classify
		person['extracted_urls'] = urls
		
		urls.each do |url|
			URL_PATTERNS.each do |url_name,regex_pattern|
				person[url_name] = url if url =~ regex_pattern
			end
		end

		# at a minimum we're saving a person object with urls extracted
		# best case if we're saving a perosn + urls + some extra tags
		people.save(person)
	end

	URL_PATTERNS.each do |url_name,regex_pattern|
		puts "People with #{url_name}"
		puts people.find({url_name => { "$exists"=> "true" }}).count
	end
end

extract_links_from_people({})