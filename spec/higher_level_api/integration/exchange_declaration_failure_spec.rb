require "spec_helper"
require "rabbitmq/http/client"

describe "Exchange declaration error handling" do
  let(:connection) {}
  let(:http_client) { RabbitMQ::HTTP::Client.new("http://127.0.0.1:15672") }

  def close_all_connections!
    http_client.list_connections.each do |conn_info|
      http_client.close_connection(conn_info.name)
    end
  end

  def with_open(c = MarchHare.connect(:network_recovery_interval => 5), &block)
    begin
      block.call(c)
    ensure
      c.close if c.open?
    end
  end

  #
  # Examples
  #

  it "does not throw Java exceptions" do
    with_open do |c|
      ch = c.create_channel
      close_all_connections!
      sleep 0.5
      expect(c).not_to be_open
      expect { ch.direct("direct.exchange.exception.test", :durable => false) }.to raise_exception(MarchHare::ChannelAlreadyClosed)
    end
  end
end
