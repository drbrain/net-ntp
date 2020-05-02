require 'socket'
require 'timeout'

module Net; end # :nodoc:

class Net::NTP
  TIMEOUT = 60 #:nodoc:

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

  attr_reader :host
  attr_reader :port
  attr_accessor :timeout

  ###
  # Sends an NTP datagram to the specified NTP server and returns
  # a hash based upon RFC1305 and RFC2030.
  def self.get(host, port: "ntp", timeout: TIMEOUT)
    ntp = new host, port: port, timeout: timeout

    ntp.get
  end

  def initialize(host, port: "ntp", timeout: TIMEOUT)
    @host = host
    @port = port
    @timeout = timeout
  end

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

    client_time_receive = Time.now.to_f

    data, _ = socket.recvfrom 960

    Net::NTP::Packet.response data, client_time_receive
  end

  private

  def frac2bin(frac) #:nodoc:
    bin  = ''

    while bin.length < 32
      bin += ( frac * 2 ).to_i.to_s
      frac = ( frac * 2 ) - ( frac * 2 ).to_i
    end

    bin
  end

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
require "net/ntp/version"
