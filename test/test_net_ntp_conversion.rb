require "minitest/autorun"
require "net/ntp"

class TestNetNTPConversion < Minitest::Test
  include Net::NTP::Conversion

  def test_f_to_ntp_short
    float = 0.018662

    ntp_short = f_to_ntp_short float

    assert_equal 1223, ntp_short
  end

  def test_ntp_short_to_f
    ntp_short = 1223

    float = ntp_short_to_f ntp_short

    assert_in_epsilon 0.01866, float
  end

  def test_ntp_timestamp_to_time
    ntp_timestamp = 16309648884269799420

    time_t = ntp_timestamp_to_time ntp_timestamp

    expected = Time.at 1588397247.493153989

    assert_equal expected, time_t
  end

  def test_time_to_ntp_timestamp
    time_t = Time.at 1588397247.493153989

    ntp_timestamp = time_to_ntp_timestamp time_t

    expected = 16309648884269799420

    assert_equal expected, ntp_timestamp
  end

  def test_ts_to_time
    ts = "0xe26c1358.3f31f4a9"

    time = ts_to_time ts

    expected = Time.at 1589744856.246856

    assert_equal expected, time
  end
end
