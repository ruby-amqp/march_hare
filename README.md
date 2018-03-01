# March Hare, a JRuby RabbitMQ Client

March Hare is an idiomatic, fast and well-maintained (J)Ruby DSL on top of the [RabbitMQ Java client](http://www.rabbitmq.com/api-guide.html). It strives to combine
strong parts of the Java client with over 4 years of experience using and developing [Ruby amqp gem](http://rubyamqp.info)
and [Bunny](http://rubybunny.info).

## Why March Hare

 * Concurrency support on the JVM is excellent, with many tools & approaches available. Lets make use of it.
 * RabbitMQ Java client is rock solid and supports every RabbitMQ feature. Very nice.
 * It is screaming fast thanks to all the heavy duty being done in the pretty efficient & lightweight Java code.
 * It uses synchronous APIs where it makes sense and asynchronous APIs where it makes sense. Some other [Ruby RabbitMQ clients](https://github.com/ruby-amqp)
   only use one or the other.
 * [amqp gem](https://github.com/ruby-amqp/amqp) has certain amount of baggage it cannot drop because of backwards compatibility concerns. March Hare is a
   clean room design, much more open to radical new ideas.


## What March Hare is not

March Hare is not

 * A replacement for the RabbitMQ Java client
 * An attempt to re-create 100% of the amqp gem API on top of the Java client
 * A "work queue" like Resque
 * A cure for cancer


## Project Maturity

March Hare is not a young project. Extracted from a platform that
transports more than a terabyte of data over RabbitMQ every day, it
has been around as an open source project since mid-2011 and has
reached 2.0 in late 2013.

It is based on the RabbitMQ Java client, which is officially
supported by the RabbitMQ team at [Pivotal](http://pivotal.io).


## Installation, Dependency

### With Rubygems

    gem install march_hare

### With Bundler

    gem "march_hare", "~> 3.1.1"


## Documentation

### Guides

[MarchHare documentation guides](http://rubymarchhare.info) are mostly complete.

### Examples

Several [code examples](./examples) are available. Our [test suite](./spec/higher_level_api/integration) also has many code examples
that demonstrate various parts of the API.

### Reference

[API reference](http://reference.rubymarchhare.info) is available.


## Supported Ruby Versions

March Hare supports JRuby 9.0 or later.


## Supported JDK Versions

The project is tested against OpenJDK 8, Oracle JDK 8 and is
known to work on OpenJDK 7 and Oracle JDK 7.


## Change Log

See [ChangeLog.md](ChangeLog.md).


## Continuous Integration

[![Continuous Integration status](https://secure.travis-ci.org/ruby-amqp/march_hare.svg)](http://travis-ci.org/ruby-amqp/march_hare)

CI is hosted by [travis-ci.org](http://travis-ci.org)


## Testing

You'll need a running RabbitMQ instance with all defaults and
management plugin enabled on your local machine to run the specs.

To boot one via docker you can use:

```bash
$ docker run -p 5672:5672 -p 15672:15672 rabbitmq:3-management
```

And then you can run the specs using `rspec`:

```bash
$ bundle exec rspec
```


## License

MIT, see LICENSE in the repository root


## Copyright

Theo Hultberg, Michael Klishin, 2011-2017.
