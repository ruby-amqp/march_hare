# Hot Bunnies, a JRuby RabbitMQ Client

Hot Bunnies is an idiomatic, fast and well-maintained (J)Ruby DSL on top of the [RabbitMQ Java client](http://www.rabbitmq.com/api-guide.html). It strives to combine
strong parts of the Java client with over 4 years of experience using and developing [Ruby amqp gem](http://rubyamqp.info)
and [Bunny](http://rubybunny.info).

## Why Hot Bunnies

 * Concurrency support on the JVM is excellent, with many tools & approaches available. Lets make use of it.
 * RabbitMQ Java client is rock solid and supports every RabbitMQ feature. Very nice.
 * It is screaming fast thanks to all the heavy duty being done in the pretty efficient & lightweight Java code.
 * It uses synchronous APIs where it makes sense and asynchronous APIs where it makes sense. Some other [Ruby RabbitMQ clients](https://github.com/ruby-amqp)
   only use one or the other.
 * [amqp gem](https://github.com/ruby-amqp/amqp) has certain amount of baggage it cannot drop because of backwards compatibility concerns. Hot Bunnies is a
   clean room design, much more open to radical new ideas.
 * Someone just *had* to come up with a library called Hot Bunnies. Are your bunnies hot?


## What Hot Bunnies is not

Hot Bunnies is not

 * A replacement for the RabbitMQ Java client
 * An attempt to re-create 100% of the amqp gem API on top of the Java client
 * A "work queue" like Resque
 * A cure for cancer


## Project Maturity

Hot Bunnies is not a young project. Extracted from a system that processes a terabyte of data
over RabbitMQ every day, it has been around as an open source project since mid-2011 and will
reach 2.0 in 2013.

It is also based on the RabbitMQ Java client, which is an officially supported client
and is considered to be a reference implementation.


## Installation, Dependency

### With Rubygems

    gem install hot_bunnies --pre

### With Bundler

    gem "hot_bunnies", "~> 2.0.0.pre8"


## Documentation

### Guides

[HotBunnies documentation guides](http://hotbunnies.info) are mostly complete.

### Examples

Several [code examples](examples) are available. Our [test suite](spec/integration) also has many code examples
that demonstrate various parts of the API.

### Reference

The API reference is currently being worked on.


## Supported Ruby Versions

Hot Bunnies supports JRuby 1.7+ in 1.9 and 1.8 modes.


## Supported JDK Versions

HotBunnies is tested against OpenJDK 7, Oracle JDK 7 and is
known to work well on OpenJDK 6 and Sun JDK 6.


## Change Log

See [ChangeLog.md](ChangeLog.md).


## Continuous Integration

[![Continuous Integration status](https://secure.travis-ci.org/ruby-amqp/hot_bunnies.png)](http://travis-ci.org/ruby-amqp/hot_bunnies)

CI is hosted by [travis-ci.org](http://travis-ci.org)


## License

MIT, see LICENSE in the repository root


## Copyright

Theo Hultberg, Michael Klishin, 2011-2013.
