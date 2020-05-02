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

    @now = Time.at 1588310179.1521401
  end

  def test_response_methods
    response = "\x1C\x03\x03\xE8\x00\x00\x03\xB6\x00\x00\x04\xC7\x9F\xCBRf\xE2V.\xB0\"D\xF4\x8A^\xAB\xB0\xA3\xEF\x8Dz\xC4\xE2V/#&\xF2\xA9g\xE2V/#&\xF4Ci"

    socket = FakeUDPSocket.new
    socket.add_read_value response

    result = @ntp.stub :socket, socket do
      Time.stub :now, @now do
        @ntp.get
      end
    end

    assert_equal "159.203.82.102", result.reference_clock_identifier

    expected = Time.at 1588310179.1521401
    assert_equal expected, result.time

    expected = "\e\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00^\xAB\xB0\xA3\xEF\x93yT".b

    assert_equal expected, socket.write_values.first
  end

  def test_write
    message = "dummy message"

    response = "\x1C\x03\x03\xE8\x00\x00\x03\xB6\x00\x00\x04\xC7\x9F\xCBRf\xE2V.\xB0\"D\xF4\x8A^\xAB\xB0\xA3\xEF\x8Dz\xC4\xE2V/#&\xF2\xA9g\xE2V/#&\xF4Ci"

    socket = FakeUDPSocket.new
    socket.add_read_value response

    result = @ntp.stub :socket, socket do
      @ntp.write message
    end

    expected = Time.at 1588310179.1521401
    assert_equal expected, result.time
  end
end
