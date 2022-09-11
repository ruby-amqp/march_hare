---
title: "Error Handling and Recovery with March Hare"
layout: article
---

## About this guide

Development of a robust application, be it message publisher or
message consumer, involves dealing with multiple kinds of failures:
protocol exceptions, network failures, broker failures and so
on. Correct error handling and recovery is not easy. This guide
explains how the amqp gem helps you in dealing with issues like

 * Initial connection failures
 * Network connection failures
 * AMQP 0.9.1 connection-level exceptions
 * AMQP 0.9.1 channel-level exceptions
 * Broker failure
 * TLS (SSL) related issues

This work is licensed under a <a rel="license"
href="http://creativecommons.org/licenses/by/3.0/">Creative Commons
Attribution 3.0 Unported License</a> (including images and
stylesheets). The source is available [on
Github](https://github.com/ruby-amqp/rubymarchhare.info).


## What version of March Hare does this guide cover??

This guide covers March Hare 3.0.


## Initial RabbitMQ Connection Failures

When applications connect to the broker, they need to handle
connection failures. Networks are not 100% reliable, even with modern
system configuration tools like Chef or Puppet misconfigurations
happen and the broker might also be down. Error detection should
happen as early as possible. To handle TCP
connection failure, catch the `MarchHare::ConnectionRefused` exception:

``` ruby
begin
  conn = MarchHare.connect("amqp://guest:guest@aksjhdkajshdkj.example82737.com")
rescue MarchHare::ConnectionRefused => e
  puts "Connection to aksjhdkajshdkj.example82737.com failed"
end
```

`MarchHare.connect` will raise `MarchHare::ConnectionRefused` if a
connection fails. Code that catches it can write to a log about the
issue or use retry to execute the begin block one more time. Because
initial connection failures are due to misconfiguration or network
outage, reconnection to the same endpoint (hostname, port, vhost
combination) may result in the same issue over and over.


## Authentication Failures

Another reason why a connection may fail is authentication
failure. Handling authentication failure is very similar to handling
initial TCP connection failure:

``` ruby
begin
  conn = MarchHare.connect("amqp://guest8we78w7e8:guest2378278@127.0.0.1")
rescue MarchHare::PossibleAuthenticationFailureError => e
  puts "Could not authenticate as #{conn.username}"
end
```

In case you are wondering why the exception name has "possible" in it:
[AMQP 0.9.1 spec](http://www.rabbitmq.com/resources/specs/amqp0-9-1.pdf) requires broker
implementations to simply close TCP connection without sending any
more data when an exception (such as authentication failure) occurs
before AMQP connection is open. In practice, however, when broker
closes TCP connection between successful TCP connection and before
AMQP connection is open, it means that authentication has failed.

RabbitMQ 3.2 introduces [authentication failure notifications](http://www.rabbitmq.com/auth-notification.html)
which March Hare supports. When connecting to RabbitMQ 3.2 or later, Bunny will
raise `MarchHare::AuthenticationFailureError` when it receives a proper
authentication failure notification.


## Network Connection Failures

Detecting network connections is nearly useless if an application
cannot recover from them. Recovery is the hard part in "error handling
and recovery". Fortunately, the recovery process for many applications
follows one simple scheme that March Hare can perform automatically for
you.

Note that automatic connection recovery is a new feature and it is not
nearly as battle tested as the rest of the library.

When March Hare detects TCP connection failure, it will try to reconnect
every 5 seconds. Currently there is no limit on the number of reconnection
attempts.

To disable automatic connection recovery, pass `:automatic_recovery => false`
to `MarchHare.connect`.


### Heartbeats and Connection Failure Detection

Due to how TCP works, it sometimes can take a while (minutes) to detect an unresponsive
peer. To make connection failure detection quicker, the protocol has a feature called
"heartbeats". Client and server exchange heartbeat frames periodically (about 1/2
the configured timeout value). When either peer detects 2 missed heartbeats, it
should consider the connection to be dead.

`:heartbeat` is the option passed to `MarchHare.connect` to configure the desired
timeout interval. We recommend setting this value in the 10-30 seconds range.

Enabling heartbeats will also ensure firewalls won't consider connections with low
activity to be stale.


### Automatic Recovery

Many applications use the same recovery strategy that consists of the following steps:

 * Re-open channels
 * For each channel, re-declare exchanges (except for predefined ones)
 * For each channel, re-declare queues
 * For each queue, recover all bindings
 * For each queue, recover all consumers

March Hare provides a feature known as "automatic recovery" that performs these steps
after connection recovery, while taking care of some of the more tricky details
such as recovery of server-named queues with consumers.

Currently the automatic recovery mode is not configurable.


## Channel-level Exceptions

Channel-level exceptions are more common than connection-level ones and often indicate
issues applications can recover from (such as consuming from or trying to delete
a queue that does not exist).

With March Hare, channel-level exceptions are raised as Ruby exceptions, for example,
`MarchHare::NotFound`, that provide access to the underlying `channel.close` method
information:

``` ruby
begin
  ch.queue_delete("queue_that_should_not_exist#{rand}")
rescue MarchHare::NotFound => e
  puts "Channel-level exception! Code: #{e.channel_close.reply_code}, message: #{e.channel_close.reply_text}"
end
```

``` ruby
begin
  ch2 = conn.create_channel
  q   = "MarchHare.examples.recovery.q#{rand}"

  ch2.queue_declare(q, :durable => false)
  ch2.queue_declare(q, :durable => true)
rescue MarchHare::PreconditionFailed => e
  puts "Channel-level exception! Code: #{e.channel_close.reply_code}, message: #{e.channel_close.reply_text}"
ensure
  conn.create_channel.queue_delete(q)
end
```


### Common channel-level exceptions and what they mean

A few channel-level exceptions are common and deserve more attention.

#### 406 Precondition Failed

<dl>
  <dt>Description</dt>
  <dd>The client requested a method that was not allowed because some precondition failed.</dd>
  <dt>What might cause it</dt>
  <dd>
    <ul>
      <li>AMQP entity (a queue or exchange) was re-declared with attributes different from original declaration. Maybe two applications or pieces of code declare the same entity with different attributes. Note that different RabbitMQ client libraries historically use slightly different defaults for entities and this may cause attribute mismatches.</li>
      <li>`MarchHare::Channel#tx_commit` or `MarchHare::Channel#tx_rollback` might be run on a channel that wasn't previously made transactional with `MarchHare::Channel#tx_select`</li>
    </ul>
  </dd>
  <dt>Example RabbitMQ error message</dt>
  <dd>
    <ul>
      <li>PRECONDITION_FAILED - parameters for queue 'MarchHare.examples.channel_exception' in vhost '/' not equivalent</li>
      <li>PRECONDITION_FAILED - channel is not transactional</li>
    </ul>
  </dd>
</dl>

#### 405 Resource Locked

<dl>
  <dt>Description</dt>
  <dd>The client attempted to work with a server entity to which it has no access because another client is working with it.</dd>
  <dt>What might cause it</dt>
  <dd>
    <ul>
      <li>Multiple applications (or different pieces of code/threads/processes/routines within a single application) might try to declare queues with the same name as exclusive.</li>
      <li>Multiple consumer across multiple or single app might be registered as exclusive for the same queue.</li>
    </ul>
  </dd>
  <dt>Example RabbitMQ error message</dt>
  <dd>RESOURCE_LOCKED - cannot obtain exclusive access to locked queue 'amqpgem.examples.queue' in vhost '/'</dd>
</dl>

#### 404 Not Found

<dl>
  <dt>Description</dt>
  <dd>The client attempted to use (publish to, delete, etc) an entity (exchange, queue) that does not exist.</dd>
  <dt>What might cause it</dt>
  <dd>Application miscalculates queue or exchange name or tries to use an entity that was deleted earlier</dd>
  <dt>Example RabbitMQ error message</dt>
  <dd>NOT_FOUND - no queue 'queue_that_should_not_exist0.6798199937619038' in vhost '/'</dd>
</dl>

#### 403 Access Refused

<dl>
  <dt>Description</dt>
  <dd>The client attempted to work with a server entity to which it has no access due to security settings.</dd>
  <dt>What might cause it</dt>
  <dd>Application tries to access a queue or exchange it has no permissions for (or right kind of permissions, for example, write permissions)</dd>
  <dt>Example RabbitMQ error message</dt>
  <dd>ACCESS_REFUSED - access to queue 'march_hare.examples.channel_exception' in vhost 'march_hare_testbed' refused for user 'march_hare_reader'</dd>
</dl>



## What to Read Next

The documentation is organized as [a number of
guides](/articles/guides.html), covering various topics.

We recommend that you read the following guides first, if possible, in this order:

 * [Troubleshooting](/articles/troubleshooting.html)
 * [Using TLS (SSL) Connections](/articles/tls.html)


## Tell Us What You Think!

Please take a moment to tell us what you think about this guide [on Twitter](http://twitter.com/rubyamqp) or the [March Hare mailing list](https://groups.google.com/forum/#!forum/ruby-amqp)

Let us know what was unclear or what has not been covered. Maybe you
do not like the guide style or grammar or discover spelling
mistakes. Reader feedback is key to making the documentation better.
