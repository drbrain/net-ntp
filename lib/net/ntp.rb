require 'socket'
require 'timeout'

module Net; end # :nodoc:

class Net::NTP
  TIME_T_OFFSET = 2208988800 # :nodoc:

  TIMEOUT = 60         #:nodoc:

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
    client_localtime      = Time.now.to_f
    client_adj_localtime  = client_localtime + TIME_T_OFFSET
    client_frac_localtime = frac2bin(client_adj_localtime)

    get_msg = (['00011011']+Array.new(12, 0)+[client_localtime, client_frac_localtime]).pack("B8 C3 N10 B32")

    socket.write get_msg

    read, = IO.select [socket], nil, nil, timeout

    # For backwards compatibility we throw a Timeout error, even
    # though the timeout is being controlled by select()
    raise Timeout::Error if read.nil?

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

require "net/ntp/packet"
require "net/ntp/version"
