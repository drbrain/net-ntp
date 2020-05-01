require "minitest/autorun"
require "net/ntp"

class TestNetNTPResponse < Minitest::Test
  def setup
    @data = "\x1C\x03\x03\xE8\x00\x00\x03\xB6\x00\x00\x04\xC7\x9F\xCBRf\xE2V.\xB0\"D\xF4\x8A^\xAB\xB0\xA3\xEF\x8Dz\xC4\xE2V/#&\xF2\xA9g\xE2V/#&\xF4Ci"

    @time = Time.at 1588310179.1521401

    @resp = Net::NTP::Response.new @data, @time.to_f
  end

  def test_all
    assert_equal 0, @resp.leap_indicator
    assert_equal Net::NTP::Response::LEAP_INDICATOR[0], @resp.leap_indicator_text
    assert_equal 3, @resp.version_number
    assert_equal 4, @resp.mode
    assert_equal "server", @resp.mode_text
    assert_equal 3, @resp.stratum
    assert_equal Net::NTP::Response::STRATUM[3], @resp.stratum_text
    assert_equal 3, @resp.poll_interval
    assert_equal(-23, @resp.precision)
    assert_in_epsilon 0.0144958, @resp.root_delay
    assert_equal 0, @resp.root_dispersion
    assert_equal "159.203.82.102", @resp.reference_clock_identifier

    assert_nil @resp.reference_clock_identifier_text

    expected = 1588310064.1338649
    assert_in_epsilon expected, @resp.reference_timestamp
    assert_in_epsilon expected, @resp.originate_timestamp
    assert_in_epsilon expected, @resp.receive_timestamp
    assert_in_epsilon expected, @resp.transmit_timestamp
    assert_in_epsilon expected, @resp.client_time_receive

    expected = Time.at 1588310179.1521401
    assert_equal expected, @resp.time
  end
end

