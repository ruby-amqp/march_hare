# TLS Certificates for March Hare Tests

This directory is for CA and client certificate/key pairs
used by the TLS connection tests..

The files it is expected to have:

 * `ca_certificate.pem`
 * `client_certificate.pem`
 * `client_key.pem`
 * `client_key.p12`

By far the easiest way to generate these files is with [tls-gen](https://github.com/michaelklishin/tls-gen/).
N.B. that RabbitMQ has to be configured to use the same CA certificate and a certificate/key
pair signed by that CA certificate.
