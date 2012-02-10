%w(../common.rb sinatra tagz).each { |c| require c }
include Tagz.globally

DB = Mongo::Connection.new.db('crunch_data_new')
people = DB.collection("person")

candcursor = people.find({ "$and" => [ {"locality" => "San Francisco Bay Area"}, { "is_exec" => { "$exists" => 0 } }, {"yes" => {"$exists" => 0}}, {"no" => {"$exists" => 0}} ] })
cand = candcursor.next()

#candlist = FasterCSV.read('candidates.tsv', :col_sep=>"\t")


get '/' do
	redirect '/candidate/'
end

get '/candidate/' do
	return "Done!" unless cand
	crunchurl = cand["crunch_profile"][0]["crunchbase_url"]
	
	if params["tags"] then
		cand["tags"] = params["tags"]
		people.save(cand)
	end
	
	tagz{

		h2_(:style => "float:left;"){
			["yes", "no", "later"].each do |action|
				a_( :style =>"margin: 1em;", :href => "/candidate/" + action ){ action }
			end
		}
		form_(:action => "/candidate/", :method => "GET", :style => "margin: 1em;" ){
			b_{ "Updated Tags!" } if params["tags"]
			br_
			tagz << "Tags:" 
			input_( :type => "text", :name => "tags", :value => cand["tags"] )
			input_( :type => "submit", :value => "submit" )
		}
		br_
		[ crunchurl, cand["linkedin_url"] ].each do |url|
			iframe_( :width => "49%", :height => "90%", :src => url ){url}
		end
	}
#	s = ''
#	s << '<h2><a style="margin: 1em;" href="/candidate/yes">yes</a>'
#	s << '<a style="margin: 1em;" href="/candidate/no">no</a>'
#	s << '<a style="margin: 1em;" href="/candidate/later">later</a></h2>'
#	s << '<br>'
#	s << '<iframe width= "49%%" height="90%%" src="%s"></iframe>' % crunchurl
#	s << '<iframe width= "49%%" height="90%%" src="%s"></iframe>' % cand["linkedin_url"]
#	s
end

get '/candidate/*' do |action|
	unless action == "yes" or action == "no" or action == "later" then
		redirect '/candidate/'
	end
	
	if action == 'yes' or action == 'no' then
		cand[action] = 1
		people.save(cand)
	end
	cand = candcursor.next()
	redirect '/candidate/'
end