class Net::NTP::Packet
  ##
  # Meaning of the #leap_indicator value

  LEAP_INDICATOR = {
    0 => "no warning",
    1 => "last minute has 61 seconds",
    2 => "last minute has 59 seconds)",
    3 => "unknown (clock unsynchronized)"
  }

  ##
  # Packet mode names

  MODE = {
    0 => 'reserved',
    1 => 'symmetric active',
    2 => 'symmetric passive',
    3 => 'client',
    4 => 'server',
    5 => 'broadcast',
    6 => 'reserved for NTP control message',
    7 => 'reserved for private use'
  }

  ##
  # Offset from NTP Epoch to TIME_T epoch

  TIME_T_OFFSET = 2_208_988_800 # :nodoc:

  @mode_handler = {}

  class << self
    attr_reader :mode_handler
  end

  ##
  # Constructs a packet from +data+ and sets #client_time_received from
  # +client_time_received+.

  def self.read data, client_time_received = nil
    leap_version_mode, = data.unpack "C"

    mode = leap_version_mode & 0x07

    packet_class = @mode_handler.fetch mode
    packet = packet_class.new
    packet.unpack data
    packet.client_time_received = client_time_received
    packet
  end

  attr_accessor :client_time_received

  def initialize
    @leap_indicator = 0
    @version        = 4
    @mode           = 0
  end

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

  def pack_leap_version_mode
    leap_version_mode = 0
    leap_version_mode += (@leap_indicator & 0b11) << 6
    leap_version_mode += (@version & 0b111) << 3
    leap_version_mode += (@mode & 0b111)
    leap_version_mode
  end

  def unpack_leap_version_mode leap_version_mode
    @leap_indicator = (leap_version_mode & 0xC0) >> 6
    @version        = (leap_version_mode & 0x38) >> 3
    @mode           = (leap_version_mode & 0x07)

    nil
  end
end
