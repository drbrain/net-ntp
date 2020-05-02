##
# Packet for NTP communication.
#
# The packet may be used to construct an outgoing NTP message or to receive an
# incoming NTP message (through ::read).
#
# For further details of packet fields see RFC5905

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
  # An incomplete list of possible meanings of the #reference_id value.
  #
  # Values come from RFC5905 and other sources

  REFERENCE_ID_DESCRIPTION = {
    "ACTS" => "NIST telephone modem",
    "CHU"  => "HF Radio CHU Ottawa, Ontario",
    "DCF"  => "LF Radio DCF77 Mainflingen, DE 77.5 kHz",
    "GOES" => "Geostationary Orbit Environment Satellite",
    "GPS"  => "Global Position System",
    "GAL"  => "Galileo Positioning System",
    "HBG"  => "LF Radio HBG Prangins, HB 75 kHz",
    "IRIG" => "Inter-Range Instrumentation Group",
    "JJY"  => "LF Radio JJY Fukushima, JP 40 kHz, Saga, JP 60 kHz",
    "LOCL" => "Uncalibrated local clock",
    "LORC" => "MF Radio LORAN C station, 100 kHz",
    "MSF"  => "LF Radio MSF Anthorn, UK 60 kHz",
    "NIST" => "NIST telephone modem",
    "OMEG" => "OMEGA radionavigation system",
    "PPS"  => "Generic pulse-per-second",
    "PTB"  => "European telephone modem",
    "TDF"  => "MF Radio Allouis, FR 162 kHz",
    "USNO" => "USNO telephone modem",
    "WWV"  => "HF Radio WWV Ft. Collins, CO",
    "WWVB" => "LF Radio WWVB Ft. Collins, CO 60 kHz",
    "WWVH" => "HF Radio WWVH Kauai, HI",
  }

  ##
  # Meaning of the #stratum value

  STRATUM = {
    0  => "unspecified or invalid",
    1  => "primary server",
    16 => "unsynchronized",
  }

  2.upto(15) do |i|
    STRATUM[i] = "secondary server"
  end

  17.upto(255) do |i|
    STRATUM[i] = "reserved"
  end

  ##
  # Offset from NTP Epoch to TIME_T epoch

  TIME_T_OFFSET = 2_208_988_800 # :nodoc:

  ##
  # The time the packet was received at the client.

  attr_accessor :client_time_received

  ##
  # Warning of the impending leap second

  attr_accessor :leap_indicator

  ##
  # Packet mode

  attr_accessor :mode

  ##
  # Time at the client when the request departed the server

  attr_accessor :origin_time

  ##
  # Maximum interval between successive messages in log₂ seconds

  attr_accessor :poll_interval

  ##
  # Precision of the system clock in log₂ seconds

  attr_accessor :precision

  ##
  # Time at the server when the request arrived from the client

  attr_accessor :receive_time

  ##
  # Identifier for a server, identifier for a reference clock or a "kiss
  # code".
  #
  # If an identifier for a reference clock you may be able to look up its
  # meaning in REFERENCE_ID_DESCRIPTION.

  attr_accessor :reference_id

  ##
  # Time when the system clock was last set or corrected

  attr_accessor :reference_time

  ##
  # Total round-trip delay to the reference clock.

  attr_accessor :root_delay

  ##
  # Total dispersion to the reference clock.

  attr_accessor :root_dispersion

  ##
  # Server stratum

  attr_accessor :stratum

  ##
  # Time at the server when the response left the client.

  attr_accessor :transmit_time

  ##
  # NTP version

  attr_accessor :version

  ##
  # Constructs a packet from +data+ and sets #client_time_received from
  # +client_time_received+.

  def self.read data, client_time_received
    packet = new
    packet.unpack data
    packet.client_time_received = client_time_received
    packet
  end

  ##
  # Creates a new Packet.
  #
  # You can fill in the various fields of a packet and send it with
  # Net::NTP#write.

  def initialize
    @client_time_received = nil

    @stratum          = 0
    @poll_interval    = 0
    @precision        = 0
    @root_delay       = 0
    @root_dispersion  = 0
    @reference_id     = ""
    @reference_time   = nil
    @origin_time      = nil
    @receive_time     = nil
    @transmit_time    = nil

    @leap_indicator = 0
    @version        = 0
    @mode           = 0
  end

  ##
  # Leap indicator in text form

  def leap_indicator_text
    @leap_indicator_text ||= LEAP_INDICATOR[@leap_indicator]
  end

  ##
  # Packet mode in text form

  def mode_text
    @mode_text ||= MODE[mode]
  end

  ##
  # Server stratum in text form

  def stratum_text
    @stratum_text ||= STRATUM[stratum]
  end

  ##
  # A description of the reference id, if one is available.
  #
  # If one is not available the reference id is returned.

  def reference_id_description
    REFERENCE_ID_DESCRIPTION.fetch @reference_id, @reference_id
  end

  alias time receive_time

  # :section: NTP format conversion methods

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
  # Calculate the offset as described in RFC5905
  #
  # Note: This method does not reject bogus or replay packets nor does it use
  # maximum precision.

  def offset
    @offset ||=
      (receive_timestamp - originate_timestamp +
       transmit_timestamp - client_time_received) / 2.0
  end

  ##
  # Returns a String representation of this packet.

  def pack
    leap_version_mode = 0
    leap_version_mode += (@leap_indicator & 0b11) << 6
    leap_version_mode += (@version & 0b111) << 3
    leap_version_mode += (@mode & 0b111)

    [
      leap_version_mode,
      @stratum,
      @poll_interval,
      @precision,
      @root_delay,
      @root_dispersion,
      @reference_id,
      time_to_ntp_timestamp(@reference_time),
      time_to_ntp_timestamp(@origin_time),
      time_to_ntp_timestamp(@receive_time),
      time_to_ntp_timestamp(@transmit_time),
    ].pack "CCCcNNa4Q>Q>Q>Q>"
  end

  alias to_s pack

  ##
  # Sets packet fields from +data+

  def unpack data
    fields = data.unpack "CCCcNNA4Q>Q>Q>Q>"

    leap_version_mode = fields.shift
    @stratum          = fields.shift
    @poll_interval    = fields.shift
    @precision        = fields.shift
    @root_delay       = ntp_short_to_f fields.shift
    @root_dispersion  = ntp_short_to_f fields.shift
    @reference_id     = unpack_reference_id @stratum, fields.shift
    @reference_time   = ntp_timestamp_to_time fields.shift
    @origin_time      = ntp_timestamp_to_time fields.shift
    @receive_time     = ntp_timestamp_to_time fields.shift
    @transmit_time    = ntp_timestamp_to_time fields.shift

    @leap_indicator = (leap_version_mode & 0xC0) >> 6
    @version        = (leap_version_mode & 0x38) >> 3
    @mode           = (leap_version_mode & 0x07)

    nil
  end

  ##
  # Unpacks the Reference ID +field+ based on the +stratum+

  def unpack_reference_id stratum, field
    if stratum < 2 then
      field.delete "\x00"
    else
      "%d.%d.%d.%d" % field.unpack("C4")
    end
  end
end
