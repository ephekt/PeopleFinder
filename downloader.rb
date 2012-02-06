%w(common.rb).each { |r| require r }

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
  puts "Fetching index files for #{CORES.join(',')}"
  
  begin
    Dir.mkdir("data")
    Dir.mkdir("data/index")
  rescue Exception => e
    puts "Creating directories failed: #{e}"
  end
  
  CORES.keys.each do |c|
    puts "Fetching #{c}"
    fetch("data/index/#{c}.js","http://api.crunchbase.com/v/1/#{c}.js")
  end
end

def fetch_records_from_indexes
  
  CORES.keys.each do |c|
    directory_path = "data/#{c}"
    begin
      Dir.mkdir directory_path
    rescue Exception => e
      puts "Creating directory failed: #{e}"
    end
    JSON.parse(File.read("data/index/#{c}.js")).in_groups_of(10000,false) do |obj_list|
      fork do
        begin
          obj_list.each do |obj|
            file = "#{directory_path}/#{obj['permalink']}"
            fetch(file,"http://api.crunchbase.com/v/1/#{CORES[c]}/#{obj['permalink']}.js")
          end
        rescue Exception => e
          puts obj_list.inspect
        end
      end
    end
  end
  
end

#fetch_indexes #Uncomment to grab index files
fetch_records_from_indexes #Uncomment to grab all files found within an index