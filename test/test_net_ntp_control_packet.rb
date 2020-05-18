require "minitest/autorun"
require "net/ntp"

class TestNetNTPControlPacket < Minitest::Test
  def setup
    @packet = Net::NTP::ControlPacket.new
  end

  def test_mode_handler
    assert_equal Net::NTP::ControlPacket, Net::NTP::Packet.mode_handler[6]
  end

  def test_request_equals
    @packet.request = :READSTAT

    assert_equal 1, @packet.opcode
  end

  def test_pack
    @packet.request = :READSTAT

    packed = @packet.pack

    expected = "&\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00".b

    assert_equal expected, packed
  end

  def test_unpack_READSTAT_response
    data = "&\x81\x00\x01\x06\x15\x00\x00\x00\x00\x00\x1C\x89*\x16:\x89)\x14:\x89(\x13\x14\x89'\x14\x14\x89&\x93\x14\x89%\x93\x14\x89$\x88\x11"

    @packet.unpack data

    assert_equal 1, @packet.sequence
    assert_equal 0, @packet.association_id
    assert_equal 0, @packet.offset
    assert_equal 28, @packet.count

    data = @packet.data

    assert_equal 7, data.size

    peer_status = data.first
    assert_equal  6, peer_status.selection
    assert_equal  3, peer_status.event_count
    assert_equal 10, peer_status.event_code
  end

  def test_unpack_READVAR_response
    data = "&\x82\x00\x00\x16\xAA;\xB2\x01\xD4\x00Y29 5.11 -0.34 14.75 0.57,\r\nfiltdisp= 0.00 1.94 3.96 5.90 7.85 9.78 11.78 13.76\r\n\x00\x00\x00"

    @packet.unpack data

    assert_equal 0, @packet.sequence
    assert_equal 15282, @packet.association_id
    assert_equal 468, @packet.offset
    assert_equal 89, @packet.count

    data = @packet.data

    expected = [
      "29 5.11 -0.34 14.75 0.57,\r\nfiltdisp= 0.00 1.94 3.96 5.90 7.85 9.78 11.78 13.76\r\n",
    ]

    assert_equal expected, data
  end

  def test_unpack_response_error_more_opcode
    @packet.unpack_response_error_more_opcode 0b11111111

    assert_equal false, @packet.request
    assert_equal true,  @packet.error
    assert_equal true,  @packet.more
    assert_equal 31,    @packet.opcode
  end
end