require "rabbitmq/http/client"

RSpec.describe "Exchange declaration error handling" do
  def with_open(c = MarchHare.connect(automatically_recover: false), &block)
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

      expect do
        ch.direct("direct.exchange.exception.test", durable: false)
        ch.direct("direct.exchange.exception.test", durable: true)
        ch.direct("direct.exchange.exception.test", durable: false)
        ch.direct("direct.exchange.exception.test", durable: true)
      end.to raise_exception(MarchHare::PreconditionFailed)

      ch2 = c.create_channel
      ch2.exchange_delete("direct.exchange.exception.test")
    end
  end
end
