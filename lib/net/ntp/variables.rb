##
# NTP variables returned from a READVAR request

class Net::NTP::Variables
  include Net::NTP::Conversion

  ##
  # Symmetric authentication delay (sysinfo)

  attr_reader :authdelay

  ##
  # Broadcast delay

  attr_reader :bcastdelay

  ##
  # Clock jitter (sysinfo)

  attr_reader :clk_jitter

  ##
  # Clock wander (sysinfo)

  attr_reader :clk_wander

  ##
  # Roundtrip delay

  attr_reader :delay

  ##
  # Total dispersion to the primary reference clock

  attr_reader :dispersion

  ##
  # Destination IP address (local to NTP server)

  attr_reader :dstadr

  ##
  # Destination port (local to NTP server)

  attr_reader :dstport

  ##
  # Filter delay

  attr_reader :filtdelay

  ##
  # Filter dispersion

  attr_reader :filtdisp

  ##
  # Filter offset

  attr_reader :filtoffset

  ##
  # Flash status word

  attr_reader :flash

  ##
  # Headway time

  attr_reader :headway

  ##
  # Host mode

  attr_reader :hmode

  ##
  # Host poll exponent (log₂ seconds, 3–17)

  attr_reader :hpoll

  ##
  # Jitter

  attr_reader :jitter

  ##
  # Key ID

  attr_reader :keyid

  ##
  # Leap warning indicator

  attr_reader :leap

  ##
  # Offset of server relative to this host

  attr_reader :offset

  ##
  # Peer host and port (sysinfo)

  attr_reader :peeradr

  ##
  # Peer mode (sysinfo)

  attr_reader :peermode

  ##
  # Peer mode

  attr_reader :pmode

  ##
  # Peer poll exponent (log₂ seconds, 3–17)

  attr_reader :ppoll

  ##
  # Precision (log₂ seconds)

  attr_reader :precision

  ##
  # Reach register

  attr_reader :reach

  ##
  # Received time

  attr_reader :rec

  ##
  # Association ID or kiss code

  attr_reader :refid

  ##
  # Reference time

  attr_reader :reftime

  ##
  # Total roundtrip delay to the primary reference clock

  attr_reader :rootdelay

  ##
  # Total dispersion to the primary reference clock

  attr_reader :rootdisp

  ##
  # Source (remote) IP address

  attr_reader :srcadr

  ##
  # Source (remote) hostname

  attr_reader :srchost

  ##
  # Source (remote) port

  attr_reader :srcport

  ##
  # Clock stratum

  attr_reader :stratum

  ##
  # System jitter (sysinfo)

  attr_reader :sys_jitter

  ##
  # Unreach counter

  attr_reader :unreach

  ##
  # Interleave delay

  attr_reader :xleave

  ##
  # Creates a new Variables object from the data contained in +packets+.

  def initialize packets
    text = packets.map(&:data).join.chomp

    pairs = text.split(/,\s+/)

    variables = pairs.map { |pair|
      pair.split "="
    }.each { |name, value|
      value =
        case name
        when "authdelay",
             "bcastdelay",
             "clk_jitter",
             "clk_wander",
             "delay",
             "dispersion",
             "jitter",
             "offset",
             "rootdelay",
             "rootdisp",
             "sys_jitter",
             "xleave" then
          Float value
        when "dstport",
             "flash",
             "headway",
             "hmode",
             "hpoll",
             "keyid",
             "leap",
             "peermode",
             "pmode",
             "ppoll",
             "precision",
             "reach",
             "srcport",
             "stratum",
             "unreach" then
          Integer value
        when "filtdelay",
             "filtdisp",
             "filtoffset" then
          fields = value.strip.split " "
          fields.map { |v|
            Float v
          }
        when "rec", "reftime" then
          ts_to_time value
        when "srchost" then
          value[1..-2]
        else
          value
        end

      instance_variable_set "@#{name}", value
    }
  end

  def pretty_print q # :nodoc:
    q.group 2, "[Variables", "]" do
      q.seplist(instance_variables.sort, -> { q.text "," }) do |name|
        q.breakable
        q.text "#{name[1..-1]}: "

        q.group 1 do
          q.breakable ''
          q.pp instance_variable_get name
        end
      end
    end
  end
end
