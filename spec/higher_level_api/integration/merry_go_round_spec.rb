require "spec_helper"

describe "A message that is proxied by multiple intermediate consumers" do
  let(:c1) do
    MarchHare.connect
  end

  let(:c2) do
    MarchHare.connect
  end

  let(:c3) do
    MarchHare.connect
  end

  let(:c4) do
    MarchHare.connect
  end

  let(:c5) do
    MarchHare.connect
  end

  after :each do
    [c1, c2, c3, c4, c5].each do |c|
      c.close if c.open?
    end
  end

  # the message flow is as follows:
  #
  # x => q4 => q3 => q2 => q1 => xs (results)
  it "reaches its final destination" do
    n   = 10000
    xs  = []

    ch1 = c1.create_channel
    q1  = ch1.queue("", :exclusive => true)
    cn1 = q1.subscribe do |_, payload|
      xs << payload
    end

    ch2 = c2.create_channel
    q2  = ch2.queue("", :exclusive => true)
    cn2 = q2.subscribe do |_, payload|
      q1.publish(payload)
    end

    ch3 = c3.create_channel
    q3  = ch2.queue("", :exclusive => true)
    cn3 = q3.subscribe do |_, payload|
      q2.publish(payload)
    end

    ch4 = c4.create_channel
    q4  = ch2.queue("", :exclusive => true)
    cn4 = q4.subscribe do |_, payload|
      q3.publish(payload)
    end

    ch5 = c5.create_channel
    x   = ch5.default_exchange

    n.times do |i|
      x.publish("msg #{i}", :routing_key => q4.name)
    end

    until xs.size == n
      sleep 0.5
    end

    expect(xs.size).to eq(n)
    expect(xs.last).to eq("msg #{n - 1}")

    [cn1, cn2, cn3, cn4].each do |cons|
      cons.cancel
    end

    [ch1, ch2, ch3, ch4, ch5].each do |ch|
      ch.close
    end
  end



  it "can stretch tens of stages" do
    s   = 32
    n   = 1000
    xs  = []
    chs = []
    qs  = []
    cs  = []

    s.times do |i|
      ch = c1.create_channel
      chs << ch

      next_q = qs.last

      q  = ch.queue("", :exclusive => true)
      qs << q

      cs << q.subscribe do |_, payload|
        if next_q
          next_q.publish(payload)
        else
          xs << payload
        end
      end
    end

    pch = c2.create_channel
    x   = pch.default_exchange

    n.times do |i|
      x.publish("msg #{i}", :routing_key => qs.last.name)
    end

    until xs.size == n
      sleep 0.5
    end

    expect(xs.size).to eq(n)
    expect(xs.last).to eq("msg #{n - 1}")

    cs.each do |cons|
      cons.cancel
    end

    chs.each do |ch|
      ch.close
    end
  end
end
