## Changes Between 2.6.0 and 2.7.0

### Support P12 Certificates for TLS Connections

It is now possible to use P12 certificates with the Bunny-like
connection options:

 * `:tls_key_cert` (a file path)
 * `:certificate_password` (as a Ruby string)

Contributed by Simon Yu.


### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to `3.4.3`.

### Host List Selection Improvements

Host selection from the list is now randomised.

Contributed by Michael Ries.



## Changes Between 2.5.0 and 2.6.0

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to `3.4.0`.


### Host Lists

It is now possible to pass the `:hosts` option to `MarchHare.connect`. When
connection to RabbitMQ (including during connection recovery), a random host
will be chosen from the list.

### Better Bunny Compatibility: the Heartbeat Option

`MarchHare.connect` now accepts `:heartbeat` as an alias for `:heartbeat_requested`
for better Bunny compatibility (and because API reference accidentally listed it).

GH issue: #57.


## Changes Between 2.4.0 and 2.5.0

### Bugfixes

* Consumers are now properly unregistered from their owning channel during recovery (#52)
* Sessions in recovery are no longer reported active until recovery has fully completed (#55)
* Error 320 (connection-forced) is now properly handled (#53)
* Fixed a race condition that could cause subscriptions utilizing manual acks to fail immediately after recovery (#54)

Contributed by Chris Heald.


## Changes Between 2.3.x and 2.4.0

### MarchHare::Exchange#publish Options Bunny Compatibility

`MarchHare::Exchange#publish` now accepts property options the same way
as [Bunny](http://rubybunny.info) does (the old way with the `:properties`
option is still supported). This improves March Hare and Bunny API compatibility.

The new way:

``` ruby
exchange.publish(payload,
                 :app_id      => "marchhare.tests",
                 :persistent  => true,
                 :priority    => 8,
                 :type        => "kinda.checkin",
                 # headers table keys can be anything
                 :headers     => {
                   "coordinates" => {
                     "latitude"  => 59.35,
                     "longitude" => 18.066667
                   },
                   "time"         => @now,
                   "participants" => 11,
                   "venue"        => "Stockholm",
                   "true_field"   => true,
                   "false_field"  => false,
                   "nil_field"    => nil,
                   "ary_field"    => ["one", 2.0, 3, [{ "abc" => 123 }]]
                 },
                 :timestamp        => @now,
                 :reply_to         => "a.sender",
                 :correlation_id   => "r-1",
                 :message_id       => "m-1",
                 :content_type     => "application/octet-stream",
                 # just an example. MK.
                 :content_encoding => "zip/zap",
                 :routing_key    => "marchhare.key")
```

The old way:

``` ruby
exchange.publish(payload,
                 :properties => {
                   :app_id      => "marchhare.tests",
                   :persistent  => true,
                   :priority    => 8,
                   :type        => "kinda.checkin",
                   # headers table keys can be anything
                   :headers     => {
                     "coordinates" => {
                       "latitude"  => 59.35,
                       "longitude" => 18.066667
                     },
                     "time"         => @now,
                     "participants" => 11,
                     "venue"        => "Stockholm",
                     "true_field"   => true,
                     "false_field"  => false,
                     "nil_field"    => nil,
                     "ary_field"    => ["one", 2.0, 3, [{ "abc" => 123 }]]
                   },
                   :timestamp        => @now,
                   :reply_to         => "a.sender",
                   :correlation_id   => "r-1",
                   :message_id       => "m-1",
                   :content_type     => "application/octet-stream",
                   # just an example. MK.
                   :content_encoding => "zip/zap"
                 },
                 :routing_key    => "marchhare.key")
```

Contributed by Devin Christensen.


## Changes Between 2.2.x and 2.3.0

### Custom Exception Handler Support

March Hare now provides a way to define a custom (unexpected) exception handler
RabbitMQ Java client will use:

``` ruby
class ExceptionHandler < com.rabbitmq.client.impl.DefaultExceptionHandler
  include com.rabbitmq.client.ExceptionHandler

  def handleConsumerException(ch, ex, consumer, tag, method_name)
    # ...
  end
end

MarchHare.connect(:exception_handler => ExceptionHandler.new)
```

An exception handler is an object that conforms to the `com.rabbitmq.client.ExceptionHandler`
interface.


### Custom Thread Factories Support

Certain environments (e.g. Google App Engine) restrict thread modification.
RabbitMQ Java client 3.3 can use a custom factory in those environments.

March Hare now exposes this functionality to Ruby in a straightforward way:

``` ruby
java_import com.google.appengine.api.ThreadManager

MarchHare.connect(:thread_factory => ThreadManager.background_thread_factory)
```

A thread factory is an object that conforms to the [j.u.c.ThreadFactory](http://docs.oracle.com/javase/7/docs/api/java/util/concurrent/ThreadFactory.html)
interface:

``` ruby
class ThreadFactory
  include java.util.concurrent.ThreadFactory

  def newThread(runnable)
    # e.g. java.lang.Thread.new(runnable)
  end
end
```

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to `3.3.4`.


## Changes Between 2.1.x and 2.2.0

### IOExceptions Conversion Fix

Causeless IOExceptions and SocketExceptions thrown by the Java client are
correctly converted to `IOError` in Ruby land.

### Client-side Flow Control Removed

`MarchHare::Channel#channel_flow` is removed. Client-side flow control
has been deprecated for some time and is now removed in the Java client.


### Confirm Hooks Recovery

Confirm hooks (callbacks) are now recovered automatically.

Contributed by Noah Magram.

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to `3.3.x`.

### Internal Exchanges

Exchanges now can be declared as internal:

``` ruby
ch = conn.create_channel
x  = ch.fanout("marchhare.tests.exchanges.internal", :internal => true)
```

Internal exchanges cannot be published to by clients and are solely used
for [Exchange-to-Exchange bindings](http://rabbitmq.com/e2e.html) and various
plugins but apps may still need to bind them. Now it is possible
to do so with March Hare.


### Custom Executor Shutdown

`MarchHare::Session#close` now will always shut down the custom
executor service it was using, if any.

### Ruby 1.8 Support Dropped

March Hare no longer officially supports Ruby 1.8.


## Changes Between 2.0.x and 2.1.0

### Full Channel State Recovery

Channel recovery now involves recovery of publisher confirms and
transaction modes.


## Changes Between 1.5.0 and 2.0.0

March Hare (previously Hot Bunnies) 2.0 has **breaking API changes**.

### New Name

March Hare is the new project name. The previous name had a sexist
meaning (unintentionally) and changing it was long overdue.


### exchange.unbind Support

`MarchHare::Exchange#unbind` is now provided to compliment
`MarchHare::Exchange#bind`.

### Safe[r] basic.ack, basic.nack and basic.reject implementation

Previously if a channel was recovered (reopened) by automatic connection
recovery before a message was acknowledged or rejected, it would cause
any operation on the channel that uses delivery tags to fail and
cause the channel to be closed.

To avoid this issue, every channel keeps a counter of how many times
it has been reopened and marks delivery tags with them. Using a stale
tag to ack or reject a message will produce no method sent to RabbitMQ.
Note that unacknowledged messages will be requeued by RabbitMQ when connection
goes down anyway.

This involves an API change: `MarchHare::Headers#delivery_tag` is now
and instance of a class that responds to `#to_i` and is accepted
by `MarchHare::Channel#ack` and related methods.

Integers are still accepted by the same methods.

## Consumer Work Pool Changes

MarchHare 1.x used to maintain a separate executor (thread pool) per non-blocking
consumer. This is not optimal and reimplements the wheel RabbitMQ Java client
already has invented: it dispatches consumer methods in a thread pool maintained
by every connection.

Instead of maintaining its own executor, MarchHare now relies on the Java client
to do the job. The **key difference** is that `1.x` versions used to maintain
a thread pool per channel while `2.x` has a thread pool **per connection**.

It is still possible to override the executor when opening a connection by
providing an executor factory (any Ruby callable):

``` ruby
MarchHare.connect(:executor_factory => Proc.new {
  MarchHare::ThreadPools.fixed_of_size(16)
})
```

There is a shortcut that accepts a thread pool size
and takes care of the rest:

``` ruby
MarchHare.connect(:thread_pool_size => 16)
```

It has to be a factory to make sure we can allocate a new pool upon connection
recovery, since JVM executors cannot be cloned or restarted.

By default MarchHare will rely on the default RabbitMQ Java client's
executor service, which has a fixed size of 5 threads.


## Automatic Connection Recovery

MarchHare now supports automatic connection recovery from a network outage,
similar to the version [in Bunny](http://rubybunny.info/articles/error_handling.html).

It recovers

 * Connections
 * Shutdown hooks
 * Channels
 * Exchanges, queues and bindings declared on the connection
 * Consumers

and can be disabled by setting `:automatically_recover` connection option to `false`.



## Shutdown Callbacks

`MarchHare::Session#on_shutdown` and `MarchHare::Channel#on_shutdown` are two
new methods that register **shutdown hooks**. Those are executed when

 * Network connectivity to RabbitMQ is lost
 * RabbitMQ shuts down the connection (because of an error or management UI action)

The callbacks take two arguments: the entity that's being shutdown
(`MarchHare::Session` or `MarchHare::Channel`) and shutdown reason (an exception):

``` ruby
conn = MarchHare.connect
conn.on_shutdown |conn, reason|
  # ...
end
```

In addition, MarchHare channels will make sure consumers are gracefully
shutdown (thread pools stopped, blocking consumers unblocked).

These are initial steps towards easier to use error handling and recovery,
similar to what amqp gem and Bunny 0.9+ provide.


## MarchHare::Channel#on_confirm

`MarchHare::Channel#on_confirm` provides a way to define [publisher
confirms](http://www.rabbitmq.com/confirms.html) callbacks. Note that
it's typically more convenient to use
`MarchHare::Channel#wait_for_confirms` to wait for all outdated
confirms.


## connection.blocked, connection.unblocked Support

`MarchHare::Session#on_blocked` and `MarchHare::Session#on_unblocked`
are new methods that provide a way to define [blocked connection
notifications](http://www.rabbitmq.com/connection-blocked.html)
callbacks:

``` ruby
connection.on_blocked do |reason|
  puts "I am blocked now. Reason: #{reason}"
end

connection.on_unblocked do
  puts "I am unblocked now."
end
```


## Authentication Failure Notifications Support

MarchHare now supports [authentication failure notifications](http://www.rabbitmq.com/auth-notification.html) (new in RabbitMQ 3.2).


## MarchHare::Session#start

`MarchHare::Session#start` is a new no-op method that improves API
compatibility with [Bunny 0.9](http://rubybunny.info).

## MarchHare::Queue#subscribe_with, MarchHare::Queue#build_consumer

`MarchHare::Queue#subscribe_with` and `MarchHare::Queue#build_consumer` are new method
that allow using consumer objects, for example, to first instantiate a blocking consumer
and pass the reference around so it can be cancelled from a different thread later.

``` ruby
consumer_object  = q.build_consumer(:blocking => false) do |metadata, payload|
  # ...
end
consumer         = q.subscribe_with(consumer_object, :blocking => false)
```


## Consumer Cancellation Support

Passing a block for the `:on_cancellation` option to `MarchHare::Queue#subscribe`
lets you support [RabbitMQ consumer cancellation](http://www.rabbitmq.com/consumer-cancel.html). The block should take 3
arguments: a channel, a consumer and a consumer tag.


## MarchHare Operations Now Raise Ruby Exceptions

MarchHare used to expose RabbitMQ Java client's channel implementation
directly to Ruby code. This means that whenever an exception was raised,
it was a Java exception (commonly `java.io.IOException`, wrapping a shutdown
signal).

Not only this severely violates the Principle of Least Surprise, it also
makes it much harder to inspect the exception and figure out how to get
relevant information from it without reading the RabbitMQ Java client
source.

Hot Bunnies 2.0+ provides a Ruby implementation of `MarchHare::Channel`
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
    rescue MarchHare::NotFound => e
      raised = e
    end

    raised.channel_close.reply_text.should =~ /no exchange/
  end
end
```

MarchHare Ruby exceptions follow AMQP 0.9.1 exception code names:

 * `MarchHare::NotFound`
 * `MarchHare::PreconditionFailed`
 * `MarchHare::ResourceLocked`
 * `MarchHare::AccessRefused`

or have otherwise meaningful names that follow [Bunny](http://rubybunny.info) names closely:

 * `MarchHare::PossibleAuthenticationFailureError`
 * `MarchHare::ChannelAlreadyClosed`


## MarchHare::Queue#subscribe Now Returns a Consumer

**This is a breaking API change**

`MarchHare::Queue#subscribe` now returns a consumer (a `MarchHare::Consumer` instance)
that can be cancelled and contains a consumer tag.

`MarchHare::Subscription` was eliminated as redundant. All the same methods are
now available on `MarchHare::Consumer` subclasses.


## MarchHare::Queue#subscribe Uses :block => false By Default

**This is a breaking API change**

`MarchHare::Queue#subscribe` now uses `:block => false` by default, thus
not blocking the caller. This reduces the need to use explicitly
started threads for consumers.

This is also how Bunny 0.9 works and we've seen this default to be
a better idea.


## More Convenient Way of Creating Thread Pools

MarchHare allows you to pass your own thread pool to `MarchHare::Queue#subscribe` via
the `:executor` option. Choosing the right thread pool size can make a huge difference
in throughput for applications that use non-blocking consumers.

Previously to 2.0, MarchHare required using Java interop and being familiar
with JDK executors API to instantiate them.

MarchHare 2.0 introduces `MarchHare::ThreadPools` that has convenience methods
that make it easier:

``` ruby
# fixed size thread pool of size 1
MarchHare::ThreadPools.single_threaded
# fixed size thread pool of size 16
MarchHare::ThreadPools.fixed_of_size(16)
# dynamically growing thread pool, will allocate new threads
# as needed
MarchHare::ThreadPools.dynamically_growing

# in context
subscribe(:blocking => false, :executor => MarchHare::ThreadPools.single_threaded) do |metadata, payload|
 # ...
end
```


## RabbitMQ Java Client Upgrade

March Hare now uses RabbitMQ Java client 3.2.


## Queue Predicates

`MarchHare::Queue` now provides several predicate methods:

 * `#server_named?`
 * `#auto_delete?`
 * `#durable?`
 * `#exclusive?`

for better [Bunny 0.9](http://rubybunny.info)+ compatibility.


# Changes Between 1.4.0 and 1.5.0

## RabbitMQ Java Client Upgrade

Hot Bunnies now uses RabbitMQ Java client 3.0.x.



# Changes Between 1.3.0 and 1.4.0

## RabbitMQ Java Client Upgrade

Hot Bunnies now uses RabbitMQ Java client 2.8.7.


## TLS Support

`MarchHare.connect` now supports a new `:tls` option:

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
