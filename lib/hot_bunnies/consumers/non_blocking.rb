require "hot_bunnies/consumers/base"

module HotBunnies
  class CallbackConsumer < BaseConsumer
    def initialize(channel, callback)
      raise ArgumentError, "callback must not be nil!" if callback.nil?

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
    def initialize(channel, opts, callback, executor)
      super(channel, callback)
      @executor = executor
      @executor_submit = executor.java_method(:submit, [JavaConcurrent::Runnable.java_class])
      @opts = opts
    end

    def deliver(headers, message)
      unless @executor.shutdown?
        @executor_submit.call do
          begin
            callback(headers, message)
          rescue Exception => e
            $stderr.puts "Unhandled exception in consumer #{@consumer_tag}: #{e.message}"
          end
        end
      end
    end

    def cancel
      @cancelling.set(true)
      response = channel.basic_cancel(consumer_tag)
      @cancelled.set(true)
      @terminated.set(true)

      gracefully_shutdown

      response
    end

    def handleCancel(consumer_tag)
      super(consumer_tag)

      gracefully_shutdown
    end

    def shutdown!
      @executor.shutdown_now if @executor
    end
    alias shut_down! shutdown!

    def gracefully_shut_down
      unless @executor.await_termination(1, JavaConcurrent::TimeUnit::SECONDS)
        @executor.shutdown_now
      end
      @terminated.set(true)
    end
    alias maybe_shut_down_executor gracefully_shut_down
    alias gracefully_shutdown      gracefully_shut_down
  end
end
