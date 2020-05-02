require "socket"

module Net; end # :nodoc:

##
# Partial implementation of the NTP protocol
#
# See RFC5905 for details of NTP

class Net::NTP
  ##
  # Default timeout when waiting for responses to packets

  TIMEOUT = 60

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
  end

  ##
  # Query the NTP host for the current time.
  #
  # The current time of the remote server can be found in
  # Net::NTP::Packet#time

  def get
    packet = Net::NTP::Packet.new
    packet.leap_indicator = 3
    packet.version        = 4
    packet.mode           = 3
    packet.transmit_time  = Time.now

    write packet
  end

  ##
  # Write +packet+ to the server and return the response Packet.
  #
  # If the server does not respond within the timeout a Timeout::Error is
  # raised.

  def write packet # :nodoc:
    socket.write packet

    read, = IO.select [socket], nil, nil, @timeout

    if read.nil? then
      timeout = Net::NTP::Timeout.new @host, @port, packet, @timeout
      raise timeout
    end

    receive_time = Time.now.to_f

    data, _ = socket.recvfrom 960

    Net::NTP::Packet.read data, receive_time
  end

  private

  ##
  # The socket for NTP communication with the selected +host+ and +port+

  def socket
    @socket ||=
      begin
        s = UDPSocket.new
        s.connect @host, @port
        s
      end
  end
end

require "net/ntp/error"
require "net/ntp/packet"
