# Changes Between 1.5.0 and 1.6.0

No changes yet.


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
