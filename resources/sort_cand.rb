require 'sinatra'
require 'fastercsv'
require 'generator'

candlist = FasterCSV.read('candidates.tsv', :col_sep=>"\t")


get '/' do
	redirect '/candidate/0/'
end

get '/candidate/*/' do |num|
	s = ''
	s << '<h2><a style="margin: 1em;" href="/candidate/%s/yes">yes</a>' % num
	s << '<a style="margin: 1em;" href="/candidate/%s/no">no</a>' % num
	s << '<a style="margin: 1em;" href="/candidate/%s/later">later</a></h2>' % num
	s << '<br>'
	s << '<iframe width= "49%%" height="90%%" src="http://www.crunchbase.com/person/%s"></iframe>' % candlist[num.to_i][0]
	s << '<iframe width= "49%%" height="90%%" src="%s"></iframe>' % candlist[num.to_i][1]
	s
end

get '/candidate/*/*' do |num, action|
	unless action == "yes" or action == "no" or action == "later" then
		redirect 'candidate/%s/' % num
	end
	
	File.open( '%s_list.tsv' % action, 'a') do |f|
		f.puts( candlist[num.to_i].join("\t") )
	end
	redirect 'candidate/%d/' % ( num.to_i + 1 ) unless num.to_i == candlist.count - 1
	"Done!"
end