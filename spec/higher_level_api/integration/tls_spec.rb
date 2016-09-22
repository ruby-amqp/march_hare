describe "MarchHare.connect with TLS" do

  #
  # Examples
  #

  if !ENV["CI"] && ENV["TLS_TESTS"]
    it "supports TLS w/o custom protocol or trust manager" do
      c1 = MarchHare.connect(:tls => true, :port => 5671)
      c1.close
    end

    it "supports TLS with a client key" do
      c = MarchHare.connect(
        :tls                      => "TLSv1.1",
        :port                     => 5671,
        :tls_certificate_path     => "./spec/tls/client_key.p12",
        :tls_certificate_password => ENV.fetch("PKCS12_PASSWORD", "bunnies"))
      ch = c.create_channel
      c.close
    end
  end
end
