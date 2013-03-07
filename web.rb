%w(../common.rb sinatra tagz).each { |c| require c }
include Tagz.globally

DB = Mongo::Connection.new.db('crunchbase_data')
people = DB.collection("person")
# {"$and" => [ {"locality" => "San Francisco Bay Area"}, { "is_exec" => { "$exists" => 0 } }, {"yes" => {"$exists" => 0}}, {"no" => {"$exists" => 0}} ] }
candcursor = people.find({"$or" => [ {"locality" => "San Francisco Bay Area"}, { "linkedin_url" => { "$exists" => 1 } } ] })
cand = candcursor.next()

disable :protection

get '/' do
	redirect '/candidate/'
end

get '/list/*' do |filt|
  opts = if filt == "yes"
    {"yes" =>  1}
  else
    {"no" =>  1}
  end
  
  cands = people.find(opts)
  out = "<h2>Total Candidates: #{cands.count}</h2>"
  out += cands.map { |c| c['permalink'] }.join("<br />")
  out
end

get '/candidate/' do
	response.headers['Access-Control-Allow-Origin'] = '*'
	response.headers['X-Frame-Options'] = "GOFORIT"
	return "Done!" unless cand

	crunchurl = cand["crunch_profile"][0]["crunchbase_url"]
	
	if params["tags"] then
		cand["tags"] = params["tags"]
		people.save(cand)
	end
	
	tags = tagz{

		h2_(:style => "float:left;"){
			["yes", "no", "later"].each do |action|
				a_( :style =>"margin: 1em;", :href => "/candidate/" + action ){ action }
			end
		}
		h3_ {
			crunchurl
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
			a_(:target => "_blank", :href=>url){url}
			br_
			#iframe_( :width => "40%", :height => "25%", :src => url, :sanbox => "allow-same-origin allow-scripts allow-popups allow-forms" ){url}
		end
	}

	"<!DOCTYPE html><html lang='en-us'><head><meta charset='utf-8'><title>"+crunchurl+"</title></head><body>#{tags}</body></html>"
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