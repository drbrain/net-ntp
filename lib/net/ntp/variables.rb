##
# NTP variables returned from a READVAR request

class Net::NTP::Variables

  attr_reader :delay
  attr_reader :dispersion
  attr_reader :dstadr
  attr_reader :dstport
  attr_reader :filtdelay
  attr_reader :filtdisp
  attr_reader :filtoffset
  attr_reader :flash
  attr_reader :headway
  attr_reader :hmode
  attr_reader :hpoll
  attr_reader :jitter
  attr_reader :keyid
  attr_reader :leap
  attr_reader :offset
  attr_reader :pmode
  attr_reader :ppoll
  attr_reader :precision
  attr_reader :reach
  attr_reader :rec
  attr_reader :refid
  attr_reader :reftime
  attr_reader :rootdelay
  attr_reader :rootdisp
  attr_reader :srcadr
  attr_reader :srcport
  attr_reader :stratum
  attr_reader :unreach
  attr_reader :xleave

  def initialize packets
    text = packets.map(&:data).join.chomp

    pairs = text.split(/,\s+/)

    variables = pairs.map { |pair|
      pair.split "="
    }.each { |name, value|
      value =
        case name
        when "delay",
             "dispersion",
             "jitter",
             "offset",
             "rootdelay",
             "rootdisp",
             "xleave" then
          Float value
        when "dstport",
             "flash",
             "headway",
             "hmode",
             "hpoll",
             "keyid",
             "leap",
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
        when "rec",
             "reftime" then
          value
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
