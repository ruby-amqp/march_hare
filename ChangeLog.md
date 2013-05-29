# Changes Between 1.5.0 and 2.0.0

Hot Bunnies 2.0 has **breaking API changes**.

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
