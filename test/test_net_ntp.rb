require "minitest/autorun"
require "net/ntp"

class TestNetNTP < Minitest::Test

  def setup
    @pool = "pool.ntp.org"
    @ntp  = Net::NTP.new @pool
  end

  def test_response_methods
    result = @ntp.get

    assert_includes Net::NTP::LEAP_INDICATOR.keys, result.leap_indicator
    assert_includes Net::NTP::LEAP_INDICATOR.values, result.leap_indicator_text
    assert_equal 3, result.version_number
    assert_equal 4, result.mode
    assert_equal "server", result.mode_text
    assert_includes (0..15), result.stratum
    assert_equal Net::NTP::STRATUM[result.stratum], result.stratum_text
    assert_equal 3, result.poll_interval
    assert_equal -18, result.precision
    assert_in_delta result.root_delay, 0, 0.1
    assert_in_delta result.root_dispersion, 0, 0.1
    assert_kind_of String, result.reference_clock_identifier

    assert_nil result.reference_clock_identifier_text

    assert_operator result.reference_timestamp, :>, 1179864677
    assert_operator result.originate_timestamp, :>, 1179864677
    assert_operator result.receive_timestamp,   :>, 1179864677
    assert_operator result.transmit_timestamp,  :>, 1179864677
    assert_operator result.client_time_receive, :>, 1179864677

    assert_kind_of Time, result.time
  end
end
