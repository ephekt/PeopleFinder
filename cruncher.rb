require './common.rb'

DB = Mongo::Connection.new.db('crunchbase_data')

CORES.keys.each do |c|
  # create database collection and index
  collection = DB.collection(CORES[c])
  collection.create_index('permalink')
  
  path = "data/#{c}/"
  
  Dir.foreach(path) do |item|
    next if item.start_with?('.')
    
    begin
      file_content = File.read(path + item)
      core_object = JSON.parse(file_content)
    rescue Exception => e
      puts "Error parsing #{item}\n\n"
      next
    end
    
    if core_object["error"]
      puts "Bad file"
      next
    end

    if obj = collection.find_one({:permalink => core_object['permalink']})
      if core_object['updated_at'] > obj['crunch_profile'].last['updated_at']
        # add a new "latest" profile
        puts "Adding an updated Profile to #{obj['permalink']}"
        obj['crunch_profile'].push(core_object)
        collection.update({:permalink => obj['permalink']},obj)
        puts "Updated #{obj['permalink']}"
      end
    else
      collection.insert({
        "permalink" => core_object['permalink'],
        "crunch_profile" => [ core_object ]
      })
    end
  end

  puts nil
end