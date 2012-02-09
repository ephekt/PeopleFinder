%w(../common.rb sinatra).each { |c| require c }

DB = Mongo::Connection.new.db('crunch_data_new')
people = DB.collection("person")

candcursor = people.find({ "$and" => [ {"locality" => "San Francisco Bay Area"}, {"yes" => {"$exists" => "false"}}, {"no" => {"$exists" => "false"}} ] })
cand = candcursor.next()

#candlist = FasterCSV.read('candidates.tsv', :col_sep=>"\t")


get '/' do
	redirect '/candidate/'
end

get '/candidate/' do
	crunchurl = cand["crunch_profile"][0]["crunchbase_url"]
	
	s = ''
	s << '<h2><a style="margin: 1em;" href="/candidate/yes">yes</a>'
	s << '<a style="margin: 1em;" href="/candidate/no">no</a>'
	s << '<a style="margin: 1em;" href="/candidate/later">later</a></h2>'
	s << '<br>'
	s << '<iframe width= "49%%" height="90%%" src="%s"></iframe>' % crunchurl
	s << '<iframe width= "49%%" height="90%%" src="%s"></iframe>' % cand["linkedin_url"]
	s
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