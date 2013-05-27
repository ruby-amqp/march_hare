# Changes Between 1.5.0 and 2.0.0

Hot Bunnies 2.0 has **breaking API changes**.

## HotBunnies::Queue#subscribe Uses :block => false By Default

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
