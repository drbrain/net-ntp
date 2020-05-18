require "minitest/autorun"
require "net/ntp"

class TestNetNTPPacket < Minitest::Test
  def setup
    @time = Time.at 1588310179.1521401

    @packet = Net::NTP::Packet.new
  end
end

