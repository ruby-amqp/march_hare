# March Hare, a JRuby RabbitMQ Client

March Hare is an idiomatic, fast and well-maintained (J)Ruby DSL on top of the [RabbitMQ Java client](https://www.rabbitmq.com/client-libraries/java-api-guide). 

It strives to combine strong parts of the Java client with over many years of experience with other client libraries,
both for Ruby and other languages.

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
 * A replacement for Bunny, the most popular Ruby RabbitMQ client
 * A long running "work queue" service


## Project Maturity

March Hare has been around since 2011 and can be considered a mature library.

It is based on the [RabbitMQ Java client](https://www.rabbitmq.com/java-client.html), which is officially
supported by the [RabbitMQ team at VMware](https://github.com/rabbitmq/).


## Installation, Dependency

### With Rubygems

``` shell
gem install march_hare
```

### With Bundler

``` ruby
gem "march_hare", "~> 4.7"
```

## Documentation

### Guides

[MarchHare documentation guides](https://github.com/ruby-amqp/march_hare/tree/master/docs/guides) are now
a part of this repository and can be read directly on GitHub.

### Examples

Several [code examples](./examples) are available. Our [test suite](./spec/higher_level_api/integration) also has many code examples
that demonstrate various parts of the API.


## Supported Ruby Versions

March Hare supports JRuby 9.0 or later.


## Supported JDK Versions

March Hare requires JDK 8 or later.


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
docker run -p 5672:5672 -p 15672:15672 rabbitmq:3-management
```

And then you can run the specs using `rspec`:

```bash
bundle exec rspec
```


## License

MIT, see LICENSE in the repository root


## Copyright

(c) 2011-2013 Theo Hultberg
(c) 2013-2025 Michael S. Klishin and contributors
