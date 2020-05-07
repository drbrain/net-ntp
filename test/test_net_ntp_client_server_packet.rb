require "minitest/autorun"
require "net/ntp"

class TestNetNTPClientServerPacket < Minitest::Test
  def setup
    @packet = Net::NTP::ClientServerPacket.new
  end

  def test_mode_handler
    assert_equal Net::NTP::ClientServerPacket, Net::NTP::Packet.mode_handler[3]
    assert_equal Net::NTP::ClientServerPacket, Net::NTP::Packet.mode_handler[4]
  end

  def test_pack
    @packet.leap_indicator = 3
    @packet.version = 4
    @packet.mode = 4
    @packet.stratum = 5
    @packet.poll_interval = 6
    @packet.precision = -7
    @packet.root_delay = 8.9
    @packet.root_dispersion = 10.11
    @packet.reference_id = "192.0.2.12"
    @packet.reference_time = Time.at 14.56
    @packet.origin_time = Time.at 78.9
    @packet.receive_time = Time.at 10.11
    @packet.transmit_time = Time.at 12.13

    expected = "\xE4\x05\x06\xF9\x00\b\xE6f\x00\n\x1C(\xC0\x00\x02\f\x83\xAA~\x8E\x8F\\(\xF5\x83\xAA~\xCE\xE6fff\x83\xAA~\x8A\x1C(\xF5\xBE\x83\xAA~\x8C!G\xAE\x14".b

    assert_equal expected, @packet.pack
  end

  def test_pack_reference_id_low_stratum
    @packet.reference_id = "PPS"
    @packet.stratum = 1

    packed = @packet.pack_reference_id

    assert_equal "PPS", packed
  end

  def test_pack_reference_id_high_stratum
    @packet.reference_id = "80.80.83.0"
    @packet.stratum = 2

    packed = @packet.pack_reference_id

    assert_equal "PPS\0", packed
  end

  def test_unpack
    data = "$\x01\b\xEC\x00\x00\x00\x00\x00\x00\x00-SHM\x00\xE2W\x837\xD7y\x86\xC2\xE2W\x83?~?V\xFF\xE2W\x83?\x83\x83w\xD1\xE2W\x83?\x83\x840S"

    @packet.unpack data

    assert_equal 0, @packet.leap_indicator
    assert_equal Net::NTP::Packet::LEAP_INDICATOR[0],
                 @packet.leap_indicator_text
    assert_equal 4, @packet.version
    assert_equal 4, @packet.mode
    assert_equal "server", @packet.mode_text
    assert_equal 1, @packet.stratum
    assert_equal Net::NTP::ClientServerPacket::STRATUM[1], @packet.stratum_text
    assert_equal 8, @packet.poll_interval
    assert_equal(-20, @packet.precision)
    assert_in_epsilon 0, @packet.root_delay
    assert_in_epsilon 0.000686, @packet.root_dispersion
    assert_equal "SHM", @packet.reference_id

    assert_equal "SHM", @packet.reference_id_description

    expected_reference_time = Time.at 1588397239.841698
    assert_in_epsilon expected_reference_time.to_f, @packet.reference_time.to_f

    expected_origin_time = Time.at 1588397247.493153
    assert_in_epsilon expected_origin_time.to_f, @packet.origin_time.to_f

    expected_receive_time = Time.at 1588397247.5137239
    assert_in_epsilon expected_receive_time.to_f, @packet.receive_time.to_f

    expected_transmit_time = Time.at 1588397247.5137348
    assert_in_epsilon expected_transmit_time.to_f, @packet.transmit_time.to_f
  end

  def test_unpack_reference_id_low_stratum
    reference_id = @packet.unpack_reference_id 1, "PPS\x00"

    assert_equal "PPS", reference_id
  end

  def test_unpack_reference_id_high_stratum
    reference_id = @packet.unpack_reference_id 2, "PPS\x00"

    assert_equal "80.80.83.0", reference_id
  end
end
