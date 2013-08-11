require "hot_bunnies/consumers/base"

module HotBunnies
  class CallbackConsumer < BaseConsumer
    def initialize(channel, queue, callback)
      raise ArgumentError, "callback must not be nil!" if callback.nil?

      super(channel, queue)
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
    def initialize(channel, queue, opts, callback)
      super(channel, queue, callback)

      # during connection recovery, the executor may be shut down, e.g. due to
      # an exception. So we need a way to create a duplicate. Unfortunately, since
      # the executor can be passed as an argument, we cannot know how it was
      # instantiated. Instead we require a lambda to produce instance of an executor
      # as a workaround. MK.
      @executor_factory = opts.fetch(:executor_factory, Proc.new {
        JavaConcurrent::Executors.new_single_thread_executor
      })
      @executor         = opts.fetch(:executor, @executor_factory.call)
      @executor_submit  = @executor.java_method(:submit, [JavaConcurrent::Runnable.java_class])
      @opts             = opts
    end

    def deliver(headers, message)
      unless @executor.shutdown?
        @executor_submit.call do
          begin
            callback(headers, message)
          rescue Exception => e
            # TODO: logging
            $stderr.puts "Unhandled exception in consumer #{@consumer_tag}: #{e}"
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


    # @private
    def recover_from_network_failure
      # ensure we have a functioning executor. MK.
      @executor        = @executor_factory.call
      @executor_submit = @executor.java_method(:submit, [JavaConcurrent::Runnable.java_class])

      super
    end
  end
end
