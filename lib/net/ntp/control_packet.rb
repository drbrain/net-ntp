##
# Packet for controlling an NTP server

class Net::NTP::ControlPacket < Net::NTP::Packet
  Net::NTP::Packet.mode_handler[6] = self

  ##
  # Maps control packet opcode names to their codes
  #
  # Use these with #request=

  OPCODE_TO_CODE = {
    READSTAT:      1,
    READVAR:       2,
    WRITEVAR:      3,
    READCLOCK:     4,
    WRITECLOCK:    5,
    SETTRAP:       6,
    ASYNCMSG:      7,
    CONFIGURE:     8,
    SAVECONFIG:    9,
    READ_MRU:     10,
    READ_ORDLIST: 11,
    REQ_NONCE:    12,
    UNSETTRAP:    31,
  }

  ##
  # Map control packet opcodes to their names

  OPCODE_TO_NAME = OPCODE_TO_CODE.invert

  ##
  # Association ID to request data for

  attr_accessor :association_id

  ##
  # True if there was an error in this response

  attr_accessor :error

  ##
  # Bytes of packet data

  attr_reader :count

  ##
  # Opcode-specific data from a response

  attr_accessor :data

  ##
  # True if there is another packet after this one

  attr_accessor :more

  alias more? more

  ##
  # Offset of data in this packet in the complete response for the request

  attr_accessor :offset

  ##
  # True if this is a request packet

  attr_accessor :request

  ##
  # Sequence number of this packet

  attr_accessor :sequence

  ##
  # Opcode for this packet.
  #
  # See #request= to set this

  attr_reader :opcode

  def initialize # :nodoc:
    super

    @version = 4
    @mode    = 6

    @request = true
    @error   = false
    @more    = false
    @opcode  = 0

    @sequence       = 0
    @status         = 0
    @association_id = 0
    @offset         = 0
    @count          = 0
  end

  ##
  # Set the request opcode for this packet to +name+ which must be a name from
  # OPCODES.

  def request= name
    @opcode = OPCODE_TO_CODE.fetch name
  end

  ##
  # Returns a String representation of this packet.

  def pack
    format = "CCnnnnn"

    fields = [
      pack_leap_version_mode,
      pack_response_error_more_opcode,
      @sequence,
      @status,
      @association_id,
      @offset,
    ]

    # count field
    if @data then
      format << "a*n"

      fields.push @data.bytesize, @data, 0
    else
      fields << 0
    end

    fields.pack format
  end

  alias to_s pack

  ##
  # Pack the response, error, more and opcode fields

  def pack_response_error_more_opcode
    response =
      if @request then
        0
      else
        1 << 7
      end

    error =
      if @error then
        1 << 6
      else
        0
      end

    more =
      if @more then
        1 << 5
      else
        0
      end

    opcode = @opcode & 0b11111

    response | error | more | opcode
  end

  ##
  # Unpack fields +data+

  def unpack data
    fields = data.unpack "CCnnnnnnnn"

    unpack_leap_version_mode          fields.shift
    unpack_response_error_more_opcode fields.shift
    @sequence                       = fields.shift
    unpack_status                     fields.shift
    @association_id                 = fields.shift
    @offset                         = fields.shift
    @count                          = fields.shift

    case @opcode
    when 1 then # READSTAT
      fields = data.unpack "@12n#{@count / 2}"

      @data = fields.each_slice(2).map { |association_id, peer_status|
        unpack_peer_status association_id, peer_status
      }
    when 2 then # READVAR
      @data = data.unpack "@12Z*"
    else
      raise Net::NTP::UnknownOpcode.new self, data
    end
  end

  ##
  # Unpacks peer status from +data+ for +association_id+

  def unpack_peer_status association_id, data
    status = Net::NTP::PeerStatus.new association_id
    status.unpack data

    status
  end

  ##
  # Unpacks the response, error, and more bits and the opcode.

  def unpack_response_error_more_opcode field
    @request = (field & 0b10000000) == 0
    @error   = (field & 0b01000000) == 0b01000000
    @more    = (field & 0b00100000) == 0b00100000
    @opcode  = (field & 0b00011111)
  end

  ##
  # Unpacks the status +field+

  def unpack_status field
    @status_leap_indicator = field >> 12
    @clock_source          = (field >> 8) & 0b111111
    @system_event_counter  = (field >> 4) & 0b1111
    @system_event_code     = field        & 0b1111
  end

  def pretty_print q # :nodoc:
    q.group 2, "[ControlPacket", "]" do
      q.fill_breakable

      q.text "opcode:"
      q.fill_breakable
      q.text OPCODE_TO_NAME.fetch @opcode, @opcode
      q.fill_breakable

      if @request then
        q.text "request"
      else
        q.text "response"
      end
      q.comma_breakable

      q.text "data:"
      q.fill_breakable
      q.pp @data
    end
  end
end
