class Net::NTP::Packet
  FIELDS = %i[
    @leap_version_mode
    @stratum
    @poll_interval
    @precision
    @delay
    @delay_fb
    @root_dispersion
    @disp_fb
    @ident
    @ref_time
    @ref_time_fb
    @org_time
    @org_time_fb
    @recv_time
    @recv_time_fb
    @trans_time
    @trans_time_fb
  ]

  LEAP_INDICATOR = {
    0 => 'no warning',
    1 => 'last minute has 61 seconds',
    2 => 'last minute has 59 seconds)',
    3 => 'alarm condition (clock not synchronized)'
  }

  REFERENCE_ID_DESCRIPTION = {
    'LOCL' => 'uncalibrated local clock used as a primary reference for a subnet without external means of synchronization',
    'PPS'  => 'atomic clock or other pulse-per-second source individually calibrated to national standards',
    'ACTS' => 'NIST dialup modem service',
    'USNO' => 'USNO modem service',
    'PTB'  => 'PTB (Germany) modem service',
    'TDF'  => 'Allouis (France) Radio 164 kHz',
    'DCF'  => 'Mainflingen (Germany) Radio 77.5 kHz',
    'MSF'  => 'Rugby (UK) Radio 60 kHz',
    'WWV'  => 'Ft. Collins (US) Radio 2.5, 5, 10, 15, 20 MHz',
    'WWVB' => 'Boulder (US) Radio 60 kHz',
    'WWVH' => 'Kaui Hawaii (US) Radio 2.5, 5, 10, 15 MHz',
    'CHU'  => 'Ottawa (Canada) Radio 3330, 7335, 14670 kHz',
    'LORC' => 'LORAN-C radionavigation system',
    'OMEG' => 'OMEGA radionavigation system',
    'GPS'  => 'Global Positioning Service',
    'GOES' => 'Geostationary Orbit Environment Satellite'
  }

  STRATUM = {
    0 => 'unspecified or unavailable',
    1 => 'primary reference (e.g., radio clock)'
  }

  2.upto(15) do |i|
    STRATUM[i] = 'secondary reference (via NTP or SNTP)'
  end

  16.upto(255) do |i|
    STRATUM[i] = 'reserved'
  end

  ##
  # Offset from NTP Epoch to TIME_T epoch

  TIME_T_OFFSET = 2_208_988_800 # :nodoc:

  attr_accessor :client_time_received
  attr_accessor :leap_indicator
  attr_accessor :mode
  attr_accessor :poll_interval
  attr_accessor :version
  attr_reader :stratum
  attr_reader :precision
  attr_reader :root_delay
  attr_reader :root_dispersion
  attr_reader :reference_id
  attr_reader :reference_time
  attr_reader :origin_time
  attr_reader :receive_time
  attr_reader :transmit_time

  def self.response(data, client_time_received)
    packet = new
    packet.unpack data
    packet.client_time_received = client_time_received
    packet
  end

  def initialize
    @client_time_received = nil
  end

  def leap_indicator_text
    @leap_indicator_text ||= LEAP_INDICATOR[@leap_indicator]
  end

  def mode_text
    @mode_text ||= Net::NTP::MODE[mode]
  end

  def stratum_text
    @stratum_text ||= STRATUM[stratum]
  end

  def reference_id_description
    @reference_clock_identifier_text ||=
      REFERENCE_ID_DESCRIPTION[@reference_id]
  end

  alias time receive_time

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
    seconds  = (time.tv_sec + TIME_T_OFFSET) << 32
    fraction = (time.tv_nsec / 1e9 * 0x100000000).to_i

    seconds + fraction
  end

  # As described in http://tools.ietf.org/html/rfc958
  def offset
    @offset ||= (receive_timestamp - originate_timestamp + transmit_timestamp - client_time_received) / 2.0
  end

  def unpack data #:nodoc:
    fields = data.unpack "CCCcNNA4Q>Q>Q>Q>"

    @leap_version_mode = fields.shift
    @stratum           = fields.shift
    @poll_interval     = fields.shift
    @precision         = fields.shift
    @root_delay        = ntp_short_to_f fields.shift
    @root_dispersion   = ntp_short_to_f fields.shift
    @reference_id      = unpack_ip @stratum, fields.shift
    @reference_time    = ntp_timestamp_to_time fields.shift
    @origin_time       = ntp_timestamp_to_time fields.shift
    @receive_time      = ntp_timestamp_to_time fields.shift
    @transmit_time     = ntp_timestamp_to_time fields.shift

    @leap_indicator = (@leap_version_mode & 0xC0) >> 6
    @version        = (@leap_version_mode & 0x38) >> 3
    @mode           = (@leap_version_mode & 0x07)

    nil
  end

  def unpack_ip stratum, field #:nodoc:
    if stratum < 2 then
      field.delete "\x00"
    else
      "%d.%d.%d.%d" % field.unpack("C4")
    end
  end
end
