require 'actor'

class Actor
  def notify_exited(actor, reason)
    exit_message = nil
    @lock.receive
    begin
      return self unless @alive
      @links.delete(actor)
      if @trap_exit
        exit_message = DeadActorError.new(actor, reason)
      elsif reason
        @interrupts << DeadActorError.new(actor, reason)
        if @filter
          @filter = nil
          @ready << nil
        end
      end
    ensure
      @lock << nil
    end
    puts "Sending exit to: #{self} from #{actor}"
    send exit_message if exit_message
    self
  end
  
  def notify_link(actor)
    @lock.receive
    alive = nil
    exit_reason = nil
    begin
      alive = @alive
      exit_reason = @exit_reason
      print "Linking #{self} to #{actor}\n"
      @links << actor if alive and not @links.include? actor
    ensure
      @lock << nil
    end
    actor.notify_exited(self, exit_reason) unless alive
    self
  end
  
  
  def watchdog
    reason = nil
    begin
      yield
    rescue Exception => reason
    ensure
      links = nil
      Actor._unregister(self)
      @lock.receive
      begin
        @alive = false
        @mailbox = nil
        @interrupts = nil
        @exit_reason = reason
        links = @links
        @links = nil
      ensure
        @lock << nil
      end
      links.each do |actor|
        begin
          p [actor.object_id, self.object_id]
          actor.notify_exited(self, reason)
        rescue Exception
        end
      end
    end
  end
  
end

def process(work)
  print "Working on #{work.msg}\n"
  sleep 1
  raise "boom" if work.msg % 10 == 7
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
  supervisor = Actor.current
  puts [:supervisor, Actor.current]
  ready_workers = []
  extra_work = []

  begin

    Actor.trap_exit = true
    10.times do |x|
      # start 10 workers
      ready_workers << Actor.spawn_link do
        puts [:worker, Actor.current]
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
        f.when(DeadActorError) do |exit|
          puts "Actor exited due to: #{exit.reason}"
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
