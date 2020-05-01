require "minitest/autorun"
require "minitest/mock"
require "net/ntp"

class TestNetNTP < Minitest::Test
  class FakeUDPSocket
    attr_reader :host
    attr_reader :port
    attr_reader :write_values

    def initialize
      @host = nil
      @port = nil

      @r, @w = IO.pipe

      @read_values  = []
      @write_values = []
    end

    def add_read_value(value)
      @read_values << value

      @w.write "\000"
    end

    def to_io
      @r
    end

    # fake methods

    def connect(host, port)
      @host = host
      @port = port
    end

    def write(message)
      @write_values << message
    end

    def recvfrom(size)
      @read_values.shift
    end
  end

  def setup
    @pool = "pool.ntp.org"
    @ntp  = Net::NTP.new @pool
  end

  def test_response_methods
    response = "\x1C\x03\x03\xE8\x00\x00\x03\xB6\x00\x00\x04\xC7\x9F\xCBRf\xE2V.\xB0\"D\xF4\x8A^\xAB\xB0\xA3\xEF\x8Dz\xC4\xE2V/#&\xF2\xA9g\xE2V/#&\xF4Ci"

    socket = FakeUDPSocket.new
    socket.add_read_value response

    result = @ntp.stub :socket, socket do
      @ntp.get
    end

    assert_equal 0, result.leap_indicator
    assert_equal Net::NTP::LEAP_INDICATOR[0], result.leap_indicator_text
    assert_equal 3, result.version_number
    assert_equal 4, result.mode
    assert_equal "server", result.mode_text
    assert_equal 3, result.stratum
    assert_equal Net::NTP::STRATUM[3], result.stratum_text
    assert_equal 3, result.poll_interval
    assert_equal(-23, result.precision)
    assert_in_epsilon 0.0144958, result.root_delay
    assert_equal 0, result.root_dispersion
    assert_equal "159.203.82.102", result.reference_clock_identifier

    assert_nil result.reference_clock_identifier_text

    expected = 1588310064.1338649
    assert_in_epsilon expected, result.reference_timestamp
    assert_in_epsilon expected, result.originate_timestamp
    assert_in_epsilon expected, result.receive_timestamp
    assert_in_epsilon expected, result.transmit_timestamp
    assert_in_epsilon expected, result.client_time_receive

    expected = Time.at 1588310179.1521401
    assert_equal expected, result.time
  end
end
