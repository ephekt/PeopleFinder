%w(../common.rb sinatra).each { |c| require c }

DB = Mongo::Connection.new.db('crunch_data_new')
people = DB.collection("person")

candcursor = people.find({"linkedin_url"=> {"$exists"=>"true"}})
cand = candcursor.next()

#candlist = FasterCSV.read('candidates.tsv', :col_sep=>"\t")


get '/' do
	redirect '/candidate/'
end

get '/candidate/' do
	crunchurl = cand["crunch_profile"][0]["crunchbase_url"]
	
	s = ''
#	s << '<h2><a style="margin: 1em;" href="/candidate/%s/yes">yes</a>' % num
#	s << '<a style="margin: 1em;" href="/candidate/%s/no">no</a>' % num
	s << '<h2><a style="margin: 1em;" href="/candidate/next">later</a></h2>'
#	s << '<br>'
	s << '<iframe width= "49%%" height="90%%" src="%s"></iframe>' % crunchurl
	s << '<iframe width= "49%%" height="90%%" src="%s"></iframe>' % cand["linkedin_url"]
	s
end

get '/candidate/next' do
	cand = candcursor.next()
	redirect '/candidate/'
end

#get '/candidate/*/*' do |num, action|
#	unless action == "yes" or action == "no" or action == "later" then
#		redirect 'candidate/%s/' % num
#	end
	
#	File.open( '%s_list.tsv' % action, 'a') do |f|
#		f.puts( candlist[num.to_i].join("\t") )
#	end
#	redirect 'candidate/%d/' % ( num.to_i + 1 ) unless num.to_i == candlist.count - 1
#	"Done!"
#end