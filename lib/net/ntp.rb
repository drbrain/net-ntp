require "socket"

module Net; end # :nodoc:

##
# Partial implementation of the NTP protocol
#
# See RFC5905 for details of NTP

class Net::NTP
  ##
  # Default timeout when waiting for responses to packets

  TIMEOUT = 2.0

  ##
  # The current version of Net::NTP

  VERSION = "3.0.0"

  ##
  # NTP host to connect to

  attr_reader :host

  ##
  # NTP port to connect to

  attr_reader :port

  ##
  # Sequence number of control packets requests

  attr_reader :sequence

  ##
  # Timeout for reading a response to a packet

  attr_accessor :timeout

  ##
  # Sends an NTP datagram to the +host+ and +port+ and returns the
  # Net::NTP::Packet response.
  #
  # See also ::new

  def self.get(host, port: "ntp", timeout: TIMEOUT)
    ntp = new host, port: port, timeout: timeout

    ntp.get
  end

  ##
  # Create a new Net::NTP object that will connect to +host+ on +port+.
  # Methods that send packets will wait up to +timeout+ seconds for a
  # response.

  def initialize(host, port: "ntp", timeout: TIMEOUT)
    @host = host
    @port = port
    @timeout = timeout

    @sequence = 1
  end

  ##
  # Query the NTP host for the current time.
  #
  # The current time of the remote server can be found in
  # Net::NTP::Packet#time

  def get
    packet = Net::NTP::ClientServerPacket.new
    packet.leap_indicator = 3
    packet.version        = 4
    packet.mode           = 3
    packet.transmit_time  = Time.now

    write packet

    read
  end

  ##
  # Read peer statistics for all associations

  def readstat
    packet = Net::NTP::ControlPacket.new
    packet.request  = :READSTAT
    packet.sequence = @sequence

    write packet

    read
  end

  ##
  # Read peer variables of +association_id+

  def readvar association_id
    packet = Net::NTP::ControlPacket.new
    packet.request  = :READVAR
    packet.sequence = @sequence
    packet.association_id = association_id

    write packet

    responses = []

    begin
      responses << read
    end while responses.last.more?

    Net::NTP::Variables.new responses
  end

  # :section: IO

  ##
  # The socket for NTP communication with the selected +host+ and +port+

  def socket # :nodoc:
    @socket ||=
      begin
        s = UDPSocket.new
        s.connect @host, @port
        s
      end
  end

  ##
  # Reads and returns a packet from the server
  #
  # If the server does not respond within the timeout a Timeout::Error is
  # raised.

  def read
    read, = IO.select [socket], nil, nil, @timeout

    if read.nil? then
      timeout = Net::NTP::Timeout.new @host, @port, @timeout
      raise timeout
    end

    receive_time = Time.now.to_f

    data, _ = socket.recvfrom 960

    Net::NTP::Packet.read data, receive_time
  end

  ##
  # Write +packet+ to the server

  def write packet
    @sequence += 1

    socket.write packet
  end
end

require "net/ntp/error"
require "net/ntp/packet"
require "net/ntp/client_server_packet"
require "net/ntp/control_packet"
require "net/ntp/peer_status"
require "net/ntp/variables"
