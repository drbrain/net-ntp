class Net::NTP::Response
  FIELDS = %i[
    byte1
    stratum
    poll
    precision
    delay
    delay_fb
    disp
    disp_fb
    ident
    ref_time
    ref_time_fb
    org_time
    org_time_fb
    recv_time
    recv_time_fb
    trans_time
    trans_time_fb
  ]

  LEAP_INDICATOR = {
    0 => 'no warning',
    1 => 'last minute has 61 seconds',
    2 => 'last minute has 59 seconds)',
    3 => 'alarm condition (clock not synchronized)'
  }

  REFERENCE_CLOCK_IDENTIFIER = {
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

  attr_reader :client_time_receive

  def initialize(raw_data, client_time_receive)
    @raw_data             = raw_data
    @client_time_receive  = client_time_receive
    @packet_data_by_field = nil
  end

  def leap_indicator
    @leap_indicator ||= (packet_data_by_field[:byte1].bytes.first & 0xC0) >> 6
  end

  def leap_indicator_text
    @leap_indicator_text ||= LEAP_INDICATOR[leap_indicator]
  end

  def version_number
    @version_number ||= (packet_data_by_field[:byte1].bytes.first & 0x38) >> 3
  end

  def mode
    @mode ||= (packet_data_by_field[:byte1].bytes.first & 0x07)
  end

  def mode_text
    @mode_text ||= Net::NTP::MODE[mode]
  end

  def stratum
    @stratum ||= packet_data_by_field[:stratum]
  end

  def stratum_text
    @stratum_text ||= STRATUM[stratum]
  end

  def poll_interval
    @poll_interval ||= packet_data_by_field[:poll]
  end

  def precision
    @precision ||= packet_data_by_field[:precision] - 255
  end

  def root_delay
    @root_delay ||= bin2frac(packet_data_by_field[:delay_fb])
  end

  def root_dispersion
    @root_dispersion ||= packet_data_by_field[:disp]
  end

  def reference_clock_identifier
    @reference_clock_identifier ||= unpack_ip(packet_data_by_field[:stratum], packet_data_by_field[:ident])
  end

  def reference_clock_identifier_text
    @reference_clock_identifier_text ||= REFERENCE_CLOCK_IDENTIFIER[reference_clock_identifier]
  end

  def reference_timestamp
    @reference_timestamp ||= ((packet_data_by_field[:ref_time] + bin2frac(packet_data_by_field[:ref_time_fb])) - Net::NTP::TIME_T_OFFSET)
  end

  def originate_timestamp
    @originate_timestamp ||= (packet_data_by_field[:org_time] + bin2frac(packet_data_by_field[:org_time_fb]))
  end

  def receive_timestamp
    @receive_timestamp ||= ((packet_data_by_field[:recv_time] + bin2frac(packet_data_by_field[:recv_time_fb])) - Net::NTP::TIME_T_OFFSET)
  end

  def transmit_timestamp
    @transmit_timestamp ||= ((packet_data_by_field[:trans_time] + bin2frac(packet_data_by_field[:trans_time_fb])) - Net::NTP::TIME_T_OFFSET)
  end

  def time
    @time ||= Time.at(receive_timestamp)
  end

  # As described in http://tools.ietf.org/html/rfc958
  def offset
    @offset ||= (receive_timestamp - originate_timestamp + transmit_timestamp - client_time_receive) / 2.0
  end

  protected

  def packet_data_by_field #:nodoc:
    if !@packet_data_by_field
      @packetdata = @raw_data.unpack("a C3   n B16 n B16 H8   N B32 N B32   N B32 N B32")
      @packet_data_by_field = {}
      FIELDS.each do |field|
        @packet_data_by_field[field] = @packetdata.shift
      end
    end

    @packet_data_by_field
  end

  def bin2frac(bin) #:nodoc:
    frac = 0

    bin.reverse.split("").each do |b|
      frac = ( frac + b.to_i ) / 2.0
    end

    frac
  end

  def unpack_ip(stratum, tmp_ip) #:nodoc:
    if stratum < 2
      [tmp_ip].pack("H8").unpack("A4").bytes.first
    else
      ipbytes = [tmp_ip].pack("H8").unpack("C4")
      sprintf("%d.%d.%d.%d", ipbytes[0], ipbytes[1], ipbytes[2], ipbytes[3])
    end
  end
end
