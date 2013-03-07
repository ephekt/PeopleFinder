require '../common.rb'

DB = Mongo::Connection.new.db('crunchbase_data')
li_users = DB.collection('linkedin_users')
li_users.create_index('permalink')

=begin
ll.keys.each do |pl|
  profile = people.find_one({:permalink => pl},:fields =>['revisions'])['revisions'].first.last
  begin
    li_users.insert(profile)
  rescue Exception => e
    puts e.inspect
    puts people.inspect
  end
end
=end

def filter li_users, regex = /(C.O|Advisor|Director|Chairman|Marketing|Board Member|President|VP, Sales|Vice President, Sales|Chief (Executive|Operations|Operating|Revenue) Officer|Founder|Managing Partner|SVP|VP Product)/i
  non_execs = {}
  li_users.find({}).each do |p|
    is_ceo = false
    p["relationships"].each do |r|
        #p r["title"]
        is_ceo = true if r["title"] =~ regex
    end if p["relationships"]
    non_execs[p["permalink"]] = p unless is_ceo
  end

  File.open("#{Time.now.strftime('%y%m%d%M%S_results.tsv')}","w+") do |f|
    non_execs.each do |k, ne|
    
      relationships = if ne["relationships"]
        ne["relationships"].map{ |r| r["title"] }.join("\t")
      else
        ""
      end

      next unless ne["web_presences"]
      
      lin = ne["web_presences"].reject { |w| !w["external_url"].include?("linkedin.com/in") }.first["external_url"]
      
      f.write("#{k}\t#{lin}\t" + relationships + "\n")
    end
  end

  puts "We found #{non_execs.size} potential candidates"
end

filter li_users

exit

def fetch_from_linked_in file='1201285931_results.tsv', outfile='local_filtered_results.tsv'
  return unless file
  require 'fastercsv'
  require 'mechanize'
  agent = Mechanize.new
  count = 100
  attempts = 0
  File.open( outfile, "w+" ) do |f|
    FasterCSV.foreach(file, {:col_sep =>"\t"}) do |row|
      attempts += 1
      puts row.inspect
      lin = row[1]
      begin
        page = agent.get lin
      rescue Exception => e
        p e.inspect
      end
      if page then
        locality = page.search('//span[@class="locality"]').inner_text.strip!
        f.write( row.join("\t") + "\n" ) if locality == "San Francisco Bay Area"
      end
      break if attempts == count
    end
  end
  puts "DONE"
end

def tag( query, tag )
	db = Mongo::Connection.new.db('crunchbase_data')
	people = db.collection("person")
	people.find( { "$and" => [ query, { tag => { "$exists" => 0 } } ] } ).each do |person|
		person[tag] = yield( person )
		people.save(person) if person[tag] 
	end
end

def tag_twitter
	tag( { "crunch_profile.0.web_presences.0" => { "$exists"=> "true" } }, "twitter_url" ) do |person|
		person["crunch_profile"][0]["web_presences"].each do |hash|
			next hash["external_url"] if hash["external_url"] =~ /twitter\.com\/in/
		end if person["crunch_profile"][0]["web_presences"]
	end
end

def tag_linkedin
	tag( { "crunch_profile.0.web_presences.0" => { "$exists"=> "true" } }, "linkedin_url" ) do |person|
		person["crunch_profile"][0]["web_presences"].each do |hash|
			next hash["external_url"] if hash["external_url"] =~ /linkedin\.com\/in/
		end if person["crunch_profile"][0]["web_presences"]
	end
end

def tag_locality
	require 'mechanize'
	agent = Mechanize.new
	agent.history.max_size = 10
	tag( { "linkedin_url" => { "$exists" => 1 } }, "locality" ) do |person|
		begin
			page = agent.get person["linkedin_url"]
		rescue Exception => e
			p e.inspect
			sleep 0.25 #don't want to get banned
		end
		next page.search('//span[@class="locality"]').inner_text.strip! if page
	end
end

def tag_exec regex = /(C.O|Advisor|Director|Chairman|Marketing|Board Member|President|VP, Sales|Vice President, Sales|Chief (Executive|Operations|Operating|Revenue) Officer|Founder|Managing Partner|SVP|VP Product)/i
	tag( {}, "is_exec" ) do |p|
  		p["relationships"].each do |r|
    	    next 1 if r["title"] =~ regex 
    	end if p["relationships"]
	end
end