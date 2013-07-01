module HotBunnies
  class ShutdownListener
    include com.rabbitmq.client.ShutdownListener

    def initialize(&block)
      @block = block
    end

    def shutdown_completed(cause)
      @block.call(cause)
    end
  end
end
