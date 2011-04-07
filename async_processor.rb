require 'actor'

def process(work)
  print "Working on #{work.msg}\n"
  sleep 1
  #raise "boom" if work.msg % 10 == 7
end

Ready = Struct.new(:this)
Work = Struct.new(:msg)

def drain(ready, work)
  todo = ready.size < work.size ? ready.size : work.size
  # p [ready.size, work.size]
  # puts "Draining #{todo} elements"
  todo.times do
    ready.pop << work.pop
  end
end

supervisor = Actor.spawn do
  ready_workers = []
  extra_work = []

  begin

    Actor.trap_exit = true
    10.times do |x|
      # start 10 workers
      ready_workers << Actor.spawn_link do
        loop do
          Actor.receive do |f|
            f.when(Work) do |work|
              process(work)
            end
            f.when(Actor::ANY) do |x|
              p x
            end
          end
          supervisor << Ready[Actor.current]
        end
      end
    end
  
    puts "Supervising"
    loop do
      Actor.receive do |f|
        f.when(Ready) do |who|
          if work = extra_work.pop
            who.this << work
            drain(ready_workers, extra_work)
          else
            ready_workers << who.this
          end
        end
        f.when(Work) do |work|
          if worker = ready_workers.pop
            worker << work
            drain(ready_workers, extra_work)
          else
            extra_work << work
          end
        end
        f.when(Actor::ANY) do |msg|
          p msg
        end
      end
    end

  rescue Exception => ex
    # An exception thrown in spawn just makes stuff stop working with no indictation of a problem.
    puts ex.message
    puts ex.backtrace.join("\n")
  end
end

20.times do |x|
  supervisor << Work[x]
end

sleep 3

puts 'Adding more work'
20.times do |x|
  supervisor << Work[x]
end

sleep 3