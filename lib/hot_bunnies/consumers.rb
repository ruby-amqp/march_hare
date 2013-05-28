module HotBunnies
  import com.rabbitmq.client.DefaultConsumer

  class BaseConsumer < DefaultConsumer
    attr_accessor :consumer_tag

    def initialize(channel)
      super(channel)
      @channel    = channel

      @cancelling = JavaConcurrent::AtomicBoolean.new
      @cancelled  = JavaConcurrent::AtomicBoolean.new
    end

    def handleDelivery(consumer_tag, envelope, properties, body)
      body    = String.from_java_bytes(body)
      headers = Headers.new(channel, consumer_tag, envelope, properties)

      deliver(headers, body)
    end

    def handleCancel(consumer_tag)
      @cancelled.set(true)
    end

    def handleCancelOk(consumer_tag)
      @cancelled.set(true)
      @channel.unregister_consumer(consumer_tag)
    end

    def start
    end

    def deliver(headers, message)
      raise NotImplementedError, 'To be implemented by a subclass'
    end

    def cancel
      @cancelling.set(true)
      response = channel.basic_cancel(consumer_tag)
      @cancelled.set(true)

      response
    end

    def cancelled?
      @cancelling.get || @cancelled.get
    end

    def active?
      !cancelled?
    end
  end


  class CallbackConsumer < BaseConsumer
    def initialize(channel, callback)
      super(channel)
      @callback = callback
      @callback_arity = @callback.arity
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
    end

    def deliver(headers, message)
      unless @executor.shutdown?
        @executor.submit do
          begin
            callback(headers, message)
          rescue Exception => e
            $stderr.puts "Unhandled exception in consumer #{@consumer_tag}: #{e.message}"
          end
        end
      end
    end

    def cancel
      super

      maybe_shut_down_executor
    end

    def shutdown!
      @executor.shutdown_now if @executor
    end
    alias shut_down! shutdown!

    def gracefully_shut_down
      unless @executor.await_termination(1, JavaConcurrent::TimeUnit::SECONDS)
        @executor.shutdown_now
      end
    end
    alias maybe_shut_down_executor gracefully_shut_down
    alias gracefully_shutdown      gracefully_shut_down
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
      until (@cancelling.get || @cancelled.get) || JavaConcurrent::Thread.current_thread.interrupted?
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
      if (@cancelling.get || @cancelled.get) || JavaConcurrent::Thread.current_thread.interrupted?
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
