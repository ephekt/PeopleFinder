%w(rubygems json bson mongo).each { |c| require c }

db = Mongo::Connection.new.db('crunch_data')
#db.collection('person').remove({})

objects = db.collection('person')

objects.create_index('permalink')

# load individual into db
path = '/Users/miker/projects/projects/crunchd/data/person/'
bad_items = []
Dir.foreach(path) do |item|
  next if item == '.' or item == '..' or item.start_with?('.')
  # do work on real items
  begin
    person_container = objects.find_one({:permalink => item})

    person = JSON.parse(File.read(path + item))

    revs = person_container['revisions']
    if revs
      revs[ person['updated_at'] ] = person
    else
      revs = { person['updated_at'] => person }
    end
    person_container['revisions'] = revs
    objects.update({:permalink=>item},person_container)
  rescue Exception => e
    bad_items << [item,e]
  end
end

puts "Bad items: #{bad_items.size}"
bad_items.each do |bad_item|
  puts bad_item.inspect
end

puts objects.count
puts z = objects.find_one({:permalink => 'zoltn-dor'})