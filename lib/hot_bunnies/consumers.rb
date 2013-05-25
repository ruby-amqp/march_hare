module HotBunnies
  import com.rabbitmq.client.DefaultConsumer

  class BaseConsumer < DefaultConsumer
    def handleDelivery(consumer_tag, envelope, properties, body)
      body = String.from_java_bytes(body)
      headers = Headers.new(channel, consumer_tag, envelope, properties)
      deliver(headers, body)
    end

    def handleCancel(consumer_tag)
      @cancelled = true
    end

    def handleCancelOk(consumer_tag)
      @cancelled = true
    end

    def start
    end

    def deliver(headers, message)
      raise NotImplementedError, 'To be implemented by a subclass'
    end

    def cancel
      response = channel.basic_cancel(consumer_tag)
      @cancelling = true

      response
    end
  end


  class CallbackConsumer < BaseConsumer
    def initialize(channel, callback)
      super(channel)
      @callback = callback
      @callback_arity = @callback.arity
      @cancelled = false
      @cancelling = false
    end

    def callback(headers, message)
      if @callback_arity == 2
        @callback.call(headers, message)
      else
        @callback.call(message)
      end
    end
  end

  class AsyncCallbackConsumer < CallbackConsumer
    def initialize(channel, callback, executor)
      super(channel, callback)
      @executor = executor
      @tasks = []
    end

    def deliver(headers, message)
      unless @executor.shutdown?
        @executor.submit do
          callback(headers, message)
        end
      end
    end
  end

  class BlockingCallbackConsumer < CallbackConsumer
    include JavaConcurrent

    def initialize(channel, buffer_size, callback)
      super(channel, callback)
      if buffer_size
        @internal_queue = ArrayBlockingQueue.new(buffer_size)
      else
        @internal_queue = LinkedBlockingQueue.new
      end
    end

    def start
      interrupted = false
      until @cancelled || JavaConcurrent::Thread.current_thread.interrupted?
        begin
          pair = @internal_queue.take
          callback(*pair) if pair
        rescue InterruptedException => e
          interrupted = true
        end
      end
      while (pair = @internal_queue.poll)
        callback(*pair)
      end
      if interrupted
        JavaConcurrent::Thread.current_thread.interrupt
      end
    end

    def deliver(*pair)
      if @cancelling || @cancelled || JavaConcurrent::Thread.current_thread.interrupted?
        @internal_queue.offer(pair)
      else
        begin
          @internal_queue.put(pair)
        rescue InterruptedException => e
          JavaConcurrent::Thread.current_thread.interrupt
        end
      end
    end
  end
end
