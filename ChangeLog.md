## Changes Between 4.6.0 and 4.7.0 (in development)

This release adopts some of the API refinement and improvements
from Bunny.

### New Queue Helpers

Several helpers for declaring queues for different kinds of use cases:

 * `Bunny::Channel#temporary_queue` for server-named exclusive queues
 * `Bunny::Channel#durable_queue` for durable queues of any type
 * `Bunny::Channel#quorum_queue` for quorum queues
 * `Bunny::Channel#stream` for streams

### Queue Type Constants

A number queue type constants are now available:

 * `MarchHare::Queue::Types::CLASSIC`
 * `MarchHare::Queue::Types::QUORUM`
 * `MarchHare::Queue::Types::STREAM`

### Channel Configuration Block

`MarchHare::Channel.configure` is a function that allows for the newly opened
channel to be configured with a block.

```ruby
ch = connection.create_channel.configure do |new_ch|
  new_ch.prefetch(500)
end
```

### A Way to Opt-in For Explicit Consumer Cancellation Before Channel Closure

`MarchHare::Channel#cancel_consumers_before_closing!` is a method that allows for the cancellation of all consumers before channel closure.

```ruby
ch = connection.create_channel.configure do |new_ch|
  new_ch.prefetch(500)
  # `MarchHare::Channel#close` now will explicitly cancel all consumers before closing the channel
  new_ch.cancel_consumers_before_closing!
end
```

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to a `5.25.x` release.


## Changes Between 4.5.0 and 4.6.0 (Nov 10, 2023)

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to a `5.20.x` release.

## Changes Between 4.4.0 and 4.5.0 (Sep 11, 2022)

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to a `5.16.x` release.

### SLF4J Dependency Bump

This dependency bump addresses a vulnerability in SLF4J `1.7.36`.


## Changes Between 4.3.0 and 4.4.0 (October 9, 2021)

### JRuby 9.3 Support

Replaced `java_kind_of?` with `kind_of?` to support `JRuby-9.3.0.0`.

Contributed by @ThomasKoppensteiner.


## Changes Between 4.2.0 and 4.3.0 (September 30, 2020)

### SLF4J Dependency Bump

This dependency bump addresses a vulnerability in SLF4J `1.7.25`.

Contributed by Alexandru @IscencoAlex Iscenco.

GitHub issue: [ruby-amqp/march_hare#152](https://github.com/ruby-amqp/march_hare/pull/152)


## Changes Between 4.1.0 and 4.2.0 (May 6, 2020)

### Connection Closure Could Get Stuck in a Recovery Loop

Contributed by @andreaseger.

GitHub issue: [ruby-amqp/march_hare#149](https://github.com/ruby-amqp/march_hare/pull/149)

### Connection Could Fail with an Exception

Contributed by @colinsurprenant.

GitHub issue: [ruby-amqp/march_hare#145](https://github.com/ruby-amqp/march_hare/pull/145)

### SASL Config Option

Contributed by @ctpaterson.

GitHub issue: [ruby-amqp/march_hare#148](https://github.com/ruby-amqp/march_hare/pull/148)

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to a `5.9.x` release.

### Test Case Used a Port Out of the Common Ephemeral Port Range

Contributed by @ctpaterson.

GitHub issue: [ruby-amqp/march_hare#147](https://github.com/ruby-amqp/march_hare/pull/147)

### CI Matrix Updates

Contributed by @olleolleolle.

GitHub issue: [ruby-amqp/march_hare#146](https://github.com/ruby-amqp/march_hare/pull/146)


## Changes Between 4.0.0 and 4.1.0 (July 9, 2019)

### Corrected Log Messages on Connection Failure

When TCP connection failed or timed out, March Hare reported default host and port
instead of a list of addresses compiled from user-provided options.

GitHub issue: [ruby-amqp/march_hare#133](https://github.com/ruby-amqp/march_hare/issues/133).


## Changes Between 3.1.0 and 4.0.0 (July 1st, 2019)

### RabbitMQ Java Client Upgrade

This is a potentially **breaking change**.

RabbitMQ Java client dependency has been updated to a `5.7.x` release, which
**requires JDK 8**.

### Blocked Connection Notification Hook Recovery

Connections now keep track of their [`connection.[un]blocked`]() hooks and recovery them as part
of connection recovery sequence.

GitHub issue: [ruby-amqp/march_hare#142](https://github.com/ruby-amqp/march_hare/pull/142).

Contributed by [Ry Biesemeyer](https://github.com/yaauie) (Elastic).

### Ruby Logger Support

March Hare can now use a Ruby logger via the `:logger` option, which will also integrate with the Java
client's `ExceptionHandler` implementations.

GitHub issues: [ruby-amqp/march_hare#35](https://github.com/ruby-amqp/march_hare/issues/35), [ruby-amqp/march_hare#136](https://github.com/ruby-amqp/march_hare/pull/136)

Contributed by [Andreas Eger](https://github.com/andreaseger).


## Changes Between 3.0.0 and 3.1.0 (Feb 18th, 2018)

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to the final version of `4.4.2`.

### TLS/SSL (when certificate path and password is provided)

When a TLS/SSL certificate path and password is provided for a PKCS12 keystore, those certificates from that keystore will now also be used (by default) for the TLS/SSL trust instead of the `NullTrustManager`.

`options[:trust_manager]` is now available to be set when certificate path and password are provided for a PKCS12 keystore.

TLS/SSL 3.0.0 behavior when certificate path and password are provided for a PKCS12 keystore can be retained by setting `options[:trust_manager] = com.rabbitmq.client.NullTrustManager.new`.

Contributed by Jake Landis (Elastic).

### Improved Timeout Handling When Connecting

`j.u.c.TimeoutException` is now handled better during connection
initiation: more details will be provided to the user.

Contributed by Per Lundberg.


## Changes Between 2.22.0 and 3.0.0 (February 20th, 2017)

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to the final version of `4.1.0`.


## Changes Between 2.21.0 and 2.22.0 (January 14th, 2017)

### Convert Long Protocol Strings to `java.lang.String`

GitHub issue: [#109](https://github.com/ruby-amqp/march_hare/issues/109)

Contributed by Andrew Cholakian.


## Changes Between 2.20.0 and 2.21.0 (November 24th, 2016)

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to the final version of `3.6.6`.



## Changes Between 2.19.0 and 2.20.0 (November 2nd, 2016)

### Connection Recovery Should Retry on Protocol Handshake Timeout

When an intermediary such as HAproxy with no backends online
(or a problematic server node) doesn't respond to a protocol header sent
to it, RabbitMQ Java client will throw a generic operation timeout exception
because the heartbeat mechanism is not yet enabled (it has not yet negotiated
a timeout value for it!)

March Hare should handle this exception and retry, as if it was an I/O or skipped heartbeats
exception.

Kudos to Andrew Cholakian and Jordan Sissel for digging this issue out.

GitHub issues: [#107](https://github.com/ruby-amqp/march_hare/issues/107),
               [logstash-plugins/logstash-input-rabbitmq#76](https://github.com/logstash-plugins/logstash-input-rabbitmq/issues/76#issuecomment-257722124)



## Changes Between 2.18.0 and 2.19.0 (October 26th, 2016)

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to a milestone version of `3.6.6`
to include a number of bug fixes early.


### Thread Pool Leak

GitHub issue: [#97](https://github.com/ruby-amqp/march_hare/issues/97).

Contributed by Michael Reis.


### Removed Unused Thread Pool

March Hare relies on RabbitMQ Java client for consumer dispatch
but one (unused) thread pool was still instantiated.

GitHub issue: [#96](https://github.com/ruby-amqp/march_hare/issues/96).

Contributed by Ivo Anjo.


### Channel Allocation Failure Throws an Exception

GitHub issue: [#98](https://github.com/ruby-amqp/march_hare/issues/98).

Contributed by Michael Reis.



## Changes Between 2.17.0 and 2.18.0 (August 14th, 2016)

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to `3.6.5`.


## Changes Between 2.16.0 and 2.17.0 (June 15th, 2016)

### User-provided Consumer Tags

It is now possible to provide a custom consumer tag instead of
relying on RabbitMQ to generate one.

GH issue: [#92](https://github.com/ruby-amqp/march_hare/issues/92)

Contributed by Eger Andreas.

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to `3.6.2`.


## Changes Between 2.15.0 and 2.16.0

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to `3.5.7`.


## Changes Between 2.13.0 and 2.15.0

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to `3.5.6`.



## Changes Between 2.12.0 and 2.13.0

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to `3.5.5`.



## Changes Between 2.11.0 and 2.12.0

### Ruby Exceptions Thrown by More Public Methods

 * `Channel#exchange_declare`
 * `Channel#exchange_bind`
 * `Channel#exchange_unbind`

now raise Ruby exceptions instead of their Java counterparts.

Contributed by Thilo-Alexander Ginkel.

### Connection Recovery Fixed For Connections Using URIs

Connection recovery no longer fails silently if the `:uri` option was used in `Connection#new`.

Contributed by Noah Magram.


## Changes Between 2.10.0 and 2.11.0

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to `3.5.4`.


## Changes Between 2.9.0 and 2.10.0

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to `3.5.3`.

### Header Keys Stringified

Header keys are now automatically stringified so it's possible to
use symbols as keys.



## Changes Between 2.8.0 and 2.9.0

### TLS Connection Fixes

TLS connections with an explicitly provided TLS version and PKCS12 certificate
no longer fail. In addition, related connection have changed to

 * `:tls` (version as a string: `TLSv1`, `TLSv1.1`, `TLSv1.2`)
 * `:tls_certificate_path`: PKCS12 certificate path as a string
 * `:tls_certificate_password`: PKCS12 certificate password as a string

To quickly generate a PKCS12 certificate as well as CA and server certificate/key pair,
see [tls-gen](https://github.com/michaelklishin/tls-gen/).


### URI Connections Fix

Host selector no longer breaks connections that use URIs.

GH issue: [#73](https://github.com/ruby-amqp/march_hare/issues/73).


### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to `3.5.1`.


## Changes Between 2.7.0 and 2.8.0

### Support P12 Certificates for TLS Connections

It is now possible to use P12 certificates with the Bunny-like
connection options:

 * `:tls_key_cert` (a PCS12 file path)
 * `:certificate_password` (as a Ruby string)

Contributed by Simon Yu.

### RabbitMQ Java Client Upgrade

RabbitMQ Java client dependency has been updated to `3.4.3`.

### Host List Selection Improvements

Host selection from the list is now randomised.

Contributed by Michael Ries.

### Support for Consumer Callbacks with Arity < 0

Callbacks with arity < 0 now can be used delivery handlers.
See [Method#arity](http://www.ruby-doc.org/core-2.2.0/Method.html#method-i-arity)
documentation for more info.

Contributed by Roman Lishtaba.


## Changes Between 2.5.0 and 2.7.0

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
