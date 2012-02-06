%w(common.rb).each { |c| require c }

DB = Mongo::Connection.new.db('crunch_data_new')

CORES.keys.each do |c|
  # create database collection and index
  collection = DB.collection(CORES[c])
  collection.create_index('permalink')
  
  path = "data/#{c}/"
  
  Dir.foreach(path) do |item|
    next if item.start_with?('.')
    core_object = JSON.parse(File.read(path + item))
    next if core_object["error"]
    exit
    if obj = collection.find_one({:permalink => core_object['permalink']})
      if core_object['updated_at'] > obj['crunch_profile'].last['updated_at']
        # add a new "latest" profile
        puts "Adding an updated Profile to #{obj['permalink']}"
        obj['crunch_profile'].push(core_object)
        collection.update({:permalink => obj['permalink']},obj)
        puts "Updated #{obj['permalink']}"
      end
      puts "No Update needed for #{obj['permalink']}"
    else
      puts "Did not find an existing #{core_object['permalink']} Object"
      collection.insert({
        "permalink" => core_object['permalink'],
        "crunch_profile" => [ core_object ]
      })
    end
  end  
end