module HotBunnies
  import com.rabbitmq.client.DefaultConsumer

  class BaseConsumer < DefaultConsumer
    attr_accessor :consumer_tag

    def initialize(channel)
      super(channel)
      @channel    = channel

      @cancelling = JavaConcurrent::AtomicBoolean.new
      @cancelled  = JavaConcurrent::AtomicBoolean.new

      @terminated = JavaConcurrent::AtomicBoolean.new
    end

    def handleDelivery(consumer_tag, envelope, properties, body)
      body    = String.from_java_bytes(body)
      headers = Headers.new(channel, consumer_tag, envelope, properties)

      deliver(headers, body)
    end

    def handleCancel(consumer_tag)
      @cancelled.set(true)
      @channel.unregister_consumer(consumer_tag)

      if f = @opts[:on_cancellation]
        case f.arity
        when 0 then
          f.call
        when 1 then
          f.call(self)
        when 2 then
          f.call(@channel, self)
        when 3 then
          f.call(@channel, self, consumer_tag)
        else
          f.call(@channel, self, consumer_tag)
        end
      end

      @terminated.set(true)
    end

    def handleCancelOk(consumer_tag)
      @cancelled.set(true)
      @channel.unregister_consumer(consumer_tag)

      @terminated.set(true)
    end

    def start
    end

    def deliver(headers, message)
      raise NotImplementedError, 'To be implemented by a subclass'
    end

    def cancelled?
      @cancelling.get || @cancelled.get
    end

    def active?
      !terminated?
    end

    def terminated?
      @terminated.get
    end
  end
end
