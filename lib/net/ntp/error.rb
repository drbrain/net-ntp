##
# Base error class for Net::NTP

class Net::NTP::Error < RuntimeError
end

##
# Raised when the server does not become readable within Net::NTP#timeout

class Net::NTP::Timeout < Net::NTP::Error
  attr_reader :host
  attr_reader :packet
  attr_reader :port
  attr_reader :timeout

  def initialize host, port, packet, timeout
    @host    = host
    @port    = port
    @packet  = packet
    @timeout = timeout

    super "Timed out waiting #{timeout} seconds for a response from #{host}:#{port}"
  end
end
