require 'work_queue'

queue = WorkQueue.new('my_processor', :size => 20) do |work|
  print "Working on #{work}\n"
  sleep 1
  raise "boom" if work % 10 == 7
end

20.times do |x|
  queue << x
end

sleep 2

puts 'Adding more work'
20.times do |x|
  queue << x
end

sleep 2
