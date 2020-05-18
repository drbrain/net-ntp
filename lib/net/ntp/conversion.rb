##
# Methods for converting between NTP types

module Net::NTP::Conversion
  ##
  # Offset from NTP Epoch to TIME_T epoch

  TIME_T_OFFSET = 2_208_988_800 # :nodoc:

  ##
  # Converts +float+ into an NTP Short

  def f_to_ntp_short float
    integer_value = float.to_i

    seconds  = integer_value.to_i << 16
    fraction = ((float - integer_value) * 0x10000).to_i

    seconds + fraction
  end

  ##
  # Convert a NTP Short into a Float

  def ntp_short_to_f ntp_short
    seconds  = ntp_short >> 16
    fraction = (ntp_short & 0xffff).to_f / 0x10000

    seconds + fraction
  end

  ##
  # Convert an NTP Timestamp into a Time

  def ntp_timestamp_to_time ntp_timestamp
    seconds  = (ntp_timestamp >> 32) - TIME_T_OFFSET
    fraction = (ntp_timestamp & 0xffffffff).to_f / 0x100000000

    Time.at seconds + fraction
  end

  ##
  # Convert a Time +time+ to an NTP Timestamp represented as an Integer

  def time_to_ntp_timestamp time
    return 0 unless time

    seconds  = (time.tv_sec + TIME_T_OFFSET) << 32
    fraction = (time.tv_nsec / 1e9 * 0x100000000).to_i

    seconds + fraction
  end

  ##
  # Convert timestamp String +ts+ to a Time
  #
  # Only hex-format NTP Time timestamps starting with "0x" are supported.

  def ts_to_time ts
    if ts.start_with? "0x" then
      sec, frac = ts.split ".", 2
      sec  = Integer sec,  16
      frac = Integer frac, 16

      timestamp = (sec << 32) + frac

      ntp_timestamp_to_time timestamp
    else
      raise ArgumentError, "Unsupported timestamp #{timestamp}"
    end
  end
end
