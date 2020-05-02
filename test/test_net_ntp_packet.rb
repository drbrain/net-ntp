require "minitest/autorun"
require "net/ntp"

class TestNetNTPPacket < Minitest::Test
  def setup
    @time = Time.at 1588310179.1521401

    @packet = Net::NTP::Packet.new
  end

  def test_fields
    @data = "$\x01\b\xEC\x00\x00\x00\x00\x00\x00\x00-SHM\x00\xE2W\x837\xD7y\x86\xC2\xE2W\x83?~?V\xFF\xE2W\x83?\x83\x83w\xD1\xE2W\x83?\x83\x840S"

    @resp = Net::NTP::Packet.read @data, @time.to_f

    assert_equal 0, @resp.leap_indicator
    assert_equal Net::NTP::Packet::LEAP_INDICATOR[0], @resp.leap_indicator_text
    assert_equal 4, @resp.version
    assert_equal 4, @resp.mode
    assert_equal "server", @resp.mode_text
    assert_equal 1, @resp.stratum
    assert_equal Net::NTP::Packet::STRATUM[1], @resp.stratum_text
    assert_equal 8, @resp.poll_interval
    assert_equal(-20, @resp.precision)
    assert_in_epsilon 0, @resp.root_delay
    assert_in_epsilon 0.000686, @resp.root_dispersion
    assert_equal "SHM", @resp.reference_id

    assert_equal "SHM", @resp.reference_id_description

    expected_reference_time = Time.at 1588397239.841698
    assert_in_epsilon expected_reference_time.to_f, @resp.reference_time.to_f

    expected_origin_time = Time.at 1588397247.493153
    assert_in_epsilon expected_origin_time.to_f, @resp.origin_time.to_f

    expected_receive_time = Time.at 1588397247.5137239
    assert_in_epsilon expected_receive_time.to_f, @resp.receive_time.to_f

    expected_transmit_time = Time.at 1588397247.5137348
    assert_in_epsilon expected_transmit_time.to_f, @resp.transmit_time.to_f

    assert_equal @time.to_f, @resp.client_time_received

    assert_in_epsilon expected_receive_time.to_f, @resp.time.to_f
  end

  def test_ntp_short_to_f
    ntp_short = 1223

    float = @packet.ntp_short_to_f ntp_short

    assert_in_epsilon 0.01866, float
  end

  def test_ntp_timestamp_to_time
    ntp_timestamp = 16309648884269799420

    time_t = @packet.ntp_timestamp_to_time ntp_timestamp

    expected = Time.at 1588397247.493153989

    assert_equal expected, time_t
  end

  def test_time_to_ntp_timestamp
    time_t = Time.at 1588397247.493153989

    ntp_timestamp = @packet.time_to_ntp_timestamp time_t

    expected = 16309648884269799420

    assert_equal expected, ntp_timestamp
  end
end

