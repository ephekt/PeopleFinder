li_users = db.collection('linkedin_users')
li_users.create_index('permalink')

ll.keys.each do |pl|
  profile = people.find_one({:permalink => pl},:fields =>['revisions'])['revisions'].first.last
  begin
    li_users.insert(profile)
  rescue Exception => e
    puts e.inspect
    puts people.inspect
  end
end

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

def tag_linkedin
	db = Mongo::Connection.new.db('crunch_data_new')
	people = db.collection("person")
	people.find({ "$and" => [ {"crunch_profile.0.web_presences.0" => {"$exists"=> "true"}}, {"linkedin_url" => {"$exists" => 0}} ] }).each do |person|
		linkedin_url = nil
		person["crunch_profile"][0]["web_presences"].each do |hash|
			linkedin_url = hash["external_url"] if hash["external_url"] =~ /linkedin\.com\/in/
		end if person["crunch_profile"][0]["web_presences"]
		if linkedin_url then
			person["linkedin_url"] = linkedin_url
			people.save(person)
		end
	end
end

def tag_locality
    require 'mechanize'
    agent = Mechanize.new
    agent.history.max_size = 10
	db = Mongo::Connection.new.db('crunch_data_new')
	people = db.collection("person")
	people.find({ "$and" => [ { "linkedin_url" => {"$exists" => 1} }, { "locality" => {"$exists" => 0 } } ] }).each do |person|
	  begin
        page = agent.get person["linkedin_url"]
      rescue Exception => e
        p e.inspect
		sleep 0.25 #don't want to get banned
      end
      if page then
        person["locality"] = page.search('//span[@class="locality"]').inner_text.strip!
        people.save(person)
      end
	end
end

def tag_exec regex = /(C.O|Advisor|Director|Chairman|Marketing|Board Member|President|VP, Sales|Vice President, Sales|Chief (Executive|Operations|Operating|Revenue) Officer|Founder|Managing Partner|SVP|VP Product)/i
	db = Mongo::Connection.new.db('crunch_data_new')
	people = db.collection("person")
	people.find({}).each do |p|
  		p["relationships"].each do |r|
    	    if r["title"] =~ regex then
    	    {
    	    	p["is_exec"] = 1
    	    	people.save(p)
    	    }
    	end if p["relationships"]
	end
end
