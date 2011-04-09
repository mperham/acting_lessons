require 'actor'
require 'monkey_patches'

class WorkQueue
  Ready = Struct.new(:this)
  Work = Struct.new(:msg)

  attr_reader :name
  def initialize(name, options={}, &block)
    @name = name
    create_pool(options[:size] || 10, block)
  end
  
  def push(work)
    @supervisor << Work[work]
  end
  alias_method :<<, :push

  private
  
  def drain(ready, work)
    # give as much work to as many ready workers as possible
    todo = ready.size < work.size ? ready.size : work.size
    todo.times do
      ready.pop << work.pop
    end
  end

  def create_pool(size, processor)
    @supervisor = Actor.spawn do
      supervisor = Actor.current
      ready_workers = []
      extra_work = []

      Actor.trap_exit = true
      size.times do |x|
        # start 10 workers
        ready_workers << Actor.spawn_link do
          loop do
            work = Actor.receive
            processor.call(work.msg)
            supervisor << Ready[Actor.current]
          end
        end
      end

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
          f.when(Actor::DeadActorError) do |exit|
            print "Actor exited due to: #{exit.reason}\n"
            # TODO need to respawn crashed worker
          end
        end
      end
    end

  end

end