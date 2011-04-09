class Actor
  # Monkeypatch so this works with Rubinius 1.2.3 (latest).
  # 1.2.4 should have the necessary fix included.
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
    send exit_message if exit_message
    self
  end
  
  # def notify_link(actor)
  #   @lock.receive
  #   alive = nil
  #   exit_reason = nil
  #   begin
  #     alive = @alive
  #     exit_reason = @exit_reason
  #     @links << actor if alive and not @links.include? actor
  #   ensure
  #     @lock << nil
  #   end
  #   actor.notify_exited(self, exit_reason) unless alive
  #   self
  # end
  # 
  # 
  # def watchdog
  #   reason = nil
  #   begin
  #     yield
  #   rescue Exception => reason
  #   ensure
  #     links = nil
  #     Actor._unregister(self)
  #     @lock.receive
  #     begin
  #       @alive = false
  #       @mailbox = nil
  #       @interrupts = nil
  #       @exit_reason = reason
  #       links = @links
  #       @links = nil
  #     ensure
  #       @lock << nil
  #     end
  #     links.each do |actor|
  #       begin
  #         actor.notify_exited(self, reason)
  #       rescue Exception
  #       end
  #     end
  #   end
  # end
  
end
