# Changes Between 1.5.0 and 2.0.0

Hot Bunnies 2.0 has **breaking API changes**.

## Shutdown Callbacks

`HotBunnies::Session#on_shutdown` and `HotBunnies::Channel#on_shutdown` are two
new methods that register **shutdown hooks**. Those are executed when

 * Network connectivity to RabbitMQ is lost
 * RabbitMQ shuts down the connection (because of an error or management UI action)

The callbacks take two arguments: the entity that's being shutdown
(`HotBunnies::Session` or `HotBunnies::Channel`) and shutdown reason (an exception):

``` ruby
conn = HotBunnies.connect
conn.on_shutdown |conn, reason|
  # ...
end
```

In addition, HotBunnies channels will make sure consumers are gracefully
shutdown (thread pools stopped, blocking consumers unblocked).

These are initial steps towards easier to use error handling and recovery,
similar to what amqp gem and Bunny 0.9+ provide.


## HotBunnies::Session#start

`HotBunnies::Session#start` is a new no-op method that improves API
compatibility with [Bunny 0.9](http://rubybunny.info).

## HotBunnies::Queue#subscribe_with, HotBunnies::Queue#build_consumer

`HotBunnies::Queue#subscribe_with` and `HotBunnies::Queue#build_consumer` are new method
that allow using consumer objects, for example, to first instantiate a blocking consumer
and pass the reference around so it can be cancelled from a different thread later.

``` ruby
consumer_object  = q.build_consumer(:blocking => false) do |metadata, payload|
  # ...
end
consumer         = q.subscribe_with(consumer_object, :blocking => false)
```


## Consumer Cancellation Support

Passing a block for the `:on_cancellation` option to `HotBunnies::Queue#subscribe`
lets you support [RabbitMQ consumer cancellation](http://www.rabbitmq.com/consumer-cancel.html). The block should take 3
arguments: a channel, a consumer and a consumer tag.


## HotBunnies Operations Now Raise Ruby Exceptions

HotBunnies used to expose RabbitMQ Java client's channel implementation
directly to Ruby code. This means that whenever an exception was raised,
it was a Java exception (commonly `java.io.IOException`, wrapping a shutdown
signal).

Not only this severely violates the Principle of Least Surprise, it also
makes it much harder to inspect the exception and figure out how to get
relevant information from it without reading the RabbitMQ Java client
source.

Hot Bunnies 2.0+ provides a Ruby implementation of `HotBunnies::Channel`
which rescues Java exceptions and turns them into Ruby
exceptions.

For example, handling a `queue.bind` failure now can be demonstrated
with the following straightforward test:

``` ruby
context "when the exchange does not exist" do
  it "raises an exception" do
    ch = connection.create_channel
    q  = ch.queue("", :auto_delete => true)

    raised = nil
    begin
      q.bind("asyd8a9d98sa73t78hd9as^&&(&@#(*^")
    rescue HotBunnies::NotFound => e
      raised = e
    end

    raised.channel_close.reply_text.should =~ /no exchange/
  end
end
```

HotBunnies Ruby exceptions follow AMQP 0.9.1 exception code names:

 * `HotBunnies::NotFound`
 * `HotBunnies::PreconditionFailed`
 * `HotBunnies::ResourceLocked`
 * `HotBunnies::AccessRefused`

or have otherwise meaningful names that follow [Bunny](http://rubybunny.info) names closely:

 * `HotBunnies::PossibleAuthenticationFailureError`
 * `HotBunnies::ChannelAlreadyClosed`


## HotBunnies::Queue#subscribe Now Returns a Consumer

**This is a breaking API change**

`HotBunnies::Queue#subscribe` now returns a consumer (a `HotBunnies::Consumer` instance)
that can be cancelled and contains a consumer tag.

`HotBunnies::Subscription` was eliminated as redundant. All the same methods are
now available on `HotBunnies::Consumer` subclasses.


## HotBunnies::Queue#subscribe Uses :block => false By Default

**This is a breaking API change**

`HotBunnies::Queue#subscribe` now uses `:block => false` by default, thus
not blocking the caller. This reduces the need to use explicitly
started threads for consumers.

This is also how Bunny 0.9 works and we've seen this default to be
a better idea.


## More Convenient Way of Creating Thread Pools

HotBunnies allows you to pass your own thread pool to `HotBunnies::Queue#subscribe` via
the `:executor` option. Choosing the right thread pool size can make a huge difference
in throughput for applications that use non-blocking consumers.

Previously to 2.0, HotBunnies required using Java interop and being familiar
with JDK executors API to instantiate them.

HotBunnies 2.0 introduces `HotBunnies::ThreadPools` that has convenience methods
that make it easier:

``` ruby
# fixed size thread pool of size 1
HotBunnies::ThreadPools.single_threaded
# fixed size thread pool of size 16
HotBunnies::ThreadPools.fixed_of_size(16)
# dynamically growing thread pool, will allocate new threads
# as needed
HotBunnies::ThreadPools.dynamically_growing

# in context
subscribe(:blocking => false, :executor => HotBunnies::ThreadPools.single_threaded) do |metadata, payload|
 # ...
end
```


## RabbitMQ Java Client Upgrade

Hot Bunnies now uses RabbitMQ Java client 3.1.



# Changes Between 1.4.0 and 1.5.0

## RabbitMQ Java Client Upgrade

Hot Bunnies now uses RabbitMQ Java client 3.0.x.



# Changes Between 1.3.0 and 1.4.0

## RabbitMQ Java Client Upgrade

Hot Bunnies now uses RabbitMQ Java client 2.8.7.


## TLS Support

`HotBunnies.connect` now supports a new `:tls` option:

``` ruby
HotBunnies.connect(:tls => true)

HotBunnies.connect(:tls => "SSLv3")
HotBunnies.connect(:tls => "SSLv2")

HotBunnies.connect(:tls => "SSLv3", :trust_manager => custom_trust_manager)
```


## Consumer Back Pressure Improvements

  * The async consumer will not attempt to add tasks when its executor is shutting down.

  * The blocking consumer got a buffer size option that makes it create a bounded blocking queue instead of an unbounded.


## Consumer Improvements

`HotBunnies::Queue#subscribe` is now more resilient to exceptions and uses a new
executor task for each delivery. When a consumer is cancelled, any remaining messages
will be delivered instead of being ignored.
