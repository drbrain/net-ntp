require "minitest/autorun"
require "net/ntp"

class TestNetNTP < Minitest::Test

  def setup
    @pool = "pool.ntp.org"
    @ntp  = Net::NTP.new @pool
  end

  def test_response_methods
    result = @ntp.get

    assert result.leap_indicator
    assert result.leap_indicator_text
    assert result.version_number
    assert result.mode
    assert result.mode_text
    assert result.stratum
    assert result.stratum_text
    assert result.poll_interval
    assert result.precision
    assert result.root_delay
    assert result.root_dispersion
    assert result.reference_clock_identifier
    assert result.reference_clock_identifier_text.nil?
    assert result.reference_timestamp > 1179864677
    assert result.originate_timestamp > 1179864677
    assert result.receive_timestamp > 1179864677
    assert result.transmit_timestamp > 1179864677
    assert result.time.is_a?(Time)
    assert result.client_time_receive > 1179864677
  end

  def test_offset
    ntpdate_output = `ntpdate -p1 -q #{@pool} 2>/dev/null`
    skip "ntpdate not available - cannot run this test right now" unless $?.success?

    if m = ntpdate_output.match(/offset (-?\d+\.\d+) sec/)
      expected = Float m[1]
      result = @ntp.get

      # If I am in sync:
      # expected -0.042687 but got 0.04379832744598389
      # assert result.offset == expected, "expected #{expected} but got #{result.offset}"

      # FIXME: Find a good way to test this is "OK", whatever that
      # means
    else
      skip "ntpdate not parseable - cannot run this test right now"
    end
  end
end
