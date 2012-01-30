%w(rubygems json open-uri bson mongo).each { |c| require c }
class Array
  # Splits or iterates over the array in groups of size +number+,
  # padding any remaining slots with +fill_with+ unless it is +false+.
  #
  #   %w(1 2 3 4 5 6 7).in_groups_of(3) {|group| p group}
  #   ["1", "2", "3"]
  #   ["4", "5", "6"]
  #   ["7", nil, nil]
  #
  #   %w(1 2 3).in_groups_of(2, '&nbsp;') {|group| p group}
  #   ["1", "2"]
  #   ["3", "&nbsp;"]
  #
  #   %w(1 2 3).in_groups_of(2, false) {|group| p group}
  #   ["1", "2"]
  #   ["3"]
  def in_groups_of(number, fill_with = nil)
    if fill_with == false
      collection = self
    else
      # size % number gives how many extra we have;
      # subtracting from number gives how many to add;
      # modulo number ensures we don't add group of just fill.
      padding = (number - size % number) % number
      collection = dup.concat([fill_with] * padding)
    end

    if block_given?
      collection.each_slice(number) { |slice| yield(slice) }
    else
      groups = []
      collection.each_slice(number) { |group| groups << group }
      groups
    end
  end
end
def fetch(name, uri)
  if File.exists?(name)
    #puts name + " exists"
    return
  end
  
  begin
    f = File.open(name, 'w')
    puts uri
    f.write(open(uri).read)
    f.close
  rescue Exception => e
    puts "Error: #{e}"
  end
end
#cores = ["companies","people"]
#cores.each do |c|
#  fetch("data/index/#{c}.js","http://api.crunchbase.com/v/1/#{c}.js")
#end

db = Mongo::Connection.new.db('crunch_data')
#db.collection('person').remove({})

objects = db.collection('person')

objects.create_index('permalink')
#load index file into db
#JSON.parse(File.read("data/index/people.js")).each do |p|
#  objects.insert(p)
#end

# download individuals
#ids = objects.find({},{:sort => [[:permalink,:asc]]}).map { |o| o['permalink'] }
#ids.in_groups_of(10000) do |list|
#  fork do
#    list.each do |perm|
#      fetch("data/person/#{perm}","http://api.crunchbase.com/v/1/person/#{perm}.js")
#    end
#  end
#end
#puts f.size

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