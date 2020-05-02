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
