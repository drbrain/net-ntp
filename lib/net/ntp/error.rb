##
# Base error class for Net::NTP

class Net::NTP::Error < RuntimeError
end

##
# Raised when the server does not become readable within Net::NTP#timeout

class Net::NTP::Timeout < Net::NTP::Error
  ##
  # Host for the packet that timed out

  attr_reader :host

  ##
  # Sent packet that timed out

  attr_reader :packet

  ##
  # Port for the packet that timed out

  attr_reader :port

  ##
  # Timeout that was exceeded

  attr_reader :timeout

  ##
  # Create a new Timeout for +host+, +port+, +packet+, +timeout+

  def initialize host, port, packet, timeout
    @host    = host
    @port    = port
    @packet  = packet
    @timeout = timeout

    super "Timed out waiting #{timeout} seconds for a response from #{host}:#{port}"
  end
end

##
# Raised when an packet with an unknown opcode is received

class Net::NTP::UnknownOpcode < Net::NTP::Error
  ##
  # Data for packet with unknown opcode

  attr_reader :data

  ##
  # Packet with partially parsed data fields

  attr_reader :packet

  ##
  # Create a new UnknownOpcode error for +packet+ and +data+.

  def initialize packet, data
    @packet = packet
    @data   = data

    super "Unknown opcode #{@packet.opcode} unpacking a #{@packet.class} packet"
  end
end
