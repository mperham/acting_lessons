require 'work_queue'

# Create a work queue for the jobs we want to process.
# We'll create 20 workers.
QUEUE = WorkQueue.new('some_name', :size => 20) do |work|
  print "Working on #{work}\n"
  sleep 1
  raise "boom" if work % 10 == 7
end

# Now pass some jobs to be processed
20.times do |x|
  QUEUE << x
end

# do some other stuff
sleep 2

# pass some more work
puts 'Adding more work'
20.times do |x|
  QUEUE << x
end

sleep 2
