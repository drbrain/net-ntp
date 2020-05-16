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

  def test_readstat
    socket = FakeUDPSocket.new
    socket.add_read_value "&\x81\x00\x01\x06\x15\x00\x00\x00\x00\x00\x18\"\x83\x16z\"\x82\x14z\"\x81\x14\x1A\"\x7F\x93\x14\"~\x93\x14\"}\x88\x11"

    result = @ntp.stub :socket, socket do
      @ntp.readstat
    end

    sent = socket.write_values.first
    assert_equal 1, sent.opcode
    assert_equal 1, sent.sequence

    stat = Net::NTP::PeerStatus.new 8835
    stat.unpack 5754

    assert_equal stat, result.first
  end

  def test_readvar
    socket = FakeUDPSocket.new
    socket.add_read_value "&\xA2\x00\x00\x16\xAA;\xB2\x00\x00\x01\xD4srcadr=192.0.2.123, srcport=123, dstadr=192.0.2.234, dstport=123,\r\nleap=0, stratum=2, precision=-24, rootdelay=0.122, rootdisp=37.628,\r\nrefid=192.0.2.34, reftime=0xe26366b2.3a504a3c,\r\nrec=0xe2636bd5.67597978, reach=0xff, unreach=0, hmode=3, pmode=4,\r\nhpoll=7, ppoll=7, headway=4, flash=0x0, keyid=0, offset=-0.342,\r\ndelay=30.315, dispersion=8.959, jitter=8.139, xleave=0.059,\r\nfiltdelay= 32.47 34.12 57.99 33.15 42.06 30.31 60.38 31.65,\r\nfiltoffset= 1.33 1.65 13.66 1."
    socket.add_read_value "&\x82\x00\x00\x16\xAA;\xB2\x01\xD4\x00Y29 5.11 -0.34 14.75 0.57,\r\nfiltdisp= 0.00 1.94 3.96 5.90 7.85 9.78 11.78 13.76\r\n\x00\x00\x00"

    result = @ntp.stub :socket, socket do
      @ntp.readvar 123
    end

    sent = socket.write_values.first
    assert_equal 2,   sent.opcode
    assert_equal 123, sent.association_id
    assert_equal 1,   sent.sequence

    assert_kind_of Net::NTP::Variables, result
  end

  def test_write
    assert_equal 1, @ntp.sequence, "sequence precondition failed"

    message = "dummy message"

    socket = FakeUDPSocket.new

    result = @ntp.stub :socket, socket do
      @ntp.write message
    end

    assert_equal [message], socket.write_values
    assert_equal 2, @ntp.sequence
  end

  def test_read
    response = "\x1C\x03\x03\xE8\x00\x00\x03\xB6\x00\x00\x04\xC7\x9F\xCBRf\xE2V.\xB0\"D\xF4\x8A^\xAB\xB0\xA3\xEF\x8Dz\xC4\xE2V/#&\xF2\xA9g\xE2V/#&\xF4Ci"

    socket = FakeUDPSocket.new
    socket.add_read_value response

    result = @ntp.stub :socket, socket do
      @ntp.read
    end

    expected = Time.at 1588397247.5137239
    assert_in_epsilon expected.to_f, result.time.to_f
  end

  def test_read_timeout
    @ntp.timeout = 0

    socket = FakeUDPSocket.new

    e = assert_raises Net::NTP::Timeout do
      @ntp.stub :socket, socket do
        @ntp.read
      end
    end

    assert_equal "pool.ntp.org", e.host
    assert_equal "ntp",          e.port
    assert_equal 0,              e.timeout
  end
end
