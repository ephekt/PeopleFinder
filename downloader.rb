require './common.rb'

API_KEY = File.read('api.key')

# http://hidemyass.com/proxy-list/

def fetch(name, uri)
  return if File.exists?(name)

  begin
    url_content = open(uri).read
    
    File.open(name, 'w+') do |f|
      f.write url_content
    end
  rescue Exception => e
    puts "Error: #{e}"
  end
end

def fetch_indexes
  puts "Fetching index files for #{CORES.keys.join(',')}"
  
  begin
    Dir.mkdir("data")
    Dir.mkdir("data/index")
  rescue Exception => e
    puts "Creating directories failed: #{e}"
  end
  
  CORES.keys.each do |c|
    puts "Fetching #{c}"
    fetch("data/index/#{c}.js","http://api.crunchbase.com/v/1/#{c}.js?api_key=#{API_KEY}")
  end
end

def fetch_records_from_indexes
  hydra = Typhoeus::Hydra.new(:max_concurrency => 5)

  CORES.keys.each do |c|
    directory_path = "data/#{c}"

    begin
      Dir.mkdir directory_path
    rescue Exception => e
      puts "Creating directory failed: #{e}"
    end

    JSON.parse(File.read("data/index/#{c}.js")).in_groups_of(10000,false) do |obj_list|

      obj_list.each do |obj|
        file = "#{directory_path}/#{obj['permalink']}"
        next if File.exists? file

        url = "http://api.crunchbase.com/v/1/#{CORES[c]}/#{obj['permalink']}.js?api_key=#{API_KEY}"
        
        request = Typhoeus::Request.new(url)
        request.on_complete do |response|
          File.open(file,"w+") { |f| f.write response.body }
        end
        hydra.queue(request)
      end

    end
  end

  hydra.run
end

#puts "Fetching Indexes"
# fetch_indexes #Uncomment to grab index files
fetch_records_from_indexes #Uncomment to grab all files found within an index