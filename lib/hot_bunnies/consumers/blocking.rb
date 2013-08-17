require "hot_bunnies/consumers/base"

module HotBunnies
  class BlockingCallbackConsumer < CallbackConsumer
    POISON = :__poison__

    def initialize(channel, queue, buffer_size, opts, callback)
      super(channel, queue, callback)
      if buffer_size
        @internal_queue = JavaConcurrent::ArrayBlockingQueue.new(buffer_size)
      else
        @internal_queue = JavaConcurrent::LinkedBlockingQueue.new
      end

      @opts = opts
    end

    def cancel
      @cancelling.set(true)
      response = channel.basic_cancel(consumer_tag)
      @cancelled.set(true)

      @internal_queue.offer(POISON)
      @terminated.set(true)

      response
    end

    def start
      interrupted = false
      until (@cancelling.get || @cancelled.get) || JavaConcurrent::Thread.current_thread.interrupted?
        begin
          pair = @internal_queue.take
          if pair
            if pair == POISON
              @cancelling.set(true)
            else
              callback(*pair)
            end
          end
        rescue JavaConcurrent::InterruptedException => e
          interrupted = true
        end
      end
      while (pair = @internal_queue.poll)
        if pair
          if pair == POISON
            @cancelling.set(true)
          else
            callback(*pair)
          end
        end
      end
      @terminated.set(true)
      if interrupted
        JavaConcurrent::Thread.current_thread.interrupt
      end
    end

    def deliver(*pair)
      if (@cancelling.get || @cancelled.get) || JavaConcurrent::Thread.current_thread.interrupted?
        @internal_queue.offer(pair)
      else
        begin
          @internal_queue.put(pair)
        rescue JavaConcurrent::InterruptedException => e
          JavaConcurrent::Thread.current_thread.interrupt
        end
      end
    end

    def gracefully_shut_down
      @cancelling.set(true)
      @internal_queue.offer(POISON)

      @terminated.set(true)
    end

  end
end
