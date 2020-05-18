require "curses"
require "ipaddr"
require "net/ntp"
require "resolv"
require "thread"

class Net::NTP::Watch

  REFCLOCK = IPAddr.new "127.127.0.0/16"

  REFCLOCKS = {
    0 => "UNKNOWN",
    1 => "LOCAL",
    2 => "GPS_TRAK",
    3 => "WWV_PST",
    4 => "SPETRACOM",
    5 => "TRUETIME",
    6 => "IRIG_AUDIO",
    7 => "CHU_AUDIO",
    8 => "GENERIC",
    9 => "GPS_MX4200",
    10 => "GPS_AS2201",
    11 => "GPS_ARBITER",
    12 => "IRIG_TPRO",
    13 => "ATOM_LEITCH",
    14 => "MSF_EES",
    16 => "GPS_BANC",
    17 => "GPS_DATUM",
    18 => "ACTS_MODEM",
    19 => "WWV_HEATH",
    20 => "GPS_NMEA",
    21 => "GPS_VME",
    22 => "PPS",
    26 => "GPS_HP",
    27 => "MSF_ARCRON",
    28 => "SHM",
    29 => "GPS_PALISADE",
    30 => "GPS_ONCORE",
    31 => "GPS_JUPITER",
    32 => "CHRONOLOG",
    33 => "DUMBCLOCK",
    34 => "ULINK_M320",
    35 => "PCF",
    36 => "WWV_AUDIO",
    37 => "GPS_FG",
    38 => "HOPF_S",
    39 => "HOPF_P",
    40 => "JJY",
    41 => "TT_IRIG",
    42 => "GPS_ZYFER",
    43 => "GPS_RIPENCC",
    44 => "NEOCLK4X",
    45 => "PCI_TSYNC",
    46 => "GPSD_JSON",
  }

  REFCLOCKS.default = "NOT_USED"

  def self.run
    watch = new
    watch.run
  end

  attr_reader :display
  attr_reader :host
  attr_reader :message
  attr_reader :resolv

  def initialize
    @colors  = false
    @message = nil
    @display = nil

    @resolv = Resolv.new
    resolvers = @resolv.instance_variable_get :@resolvers
    dns = resolvers.find { |resolver|
      Resolv::DNS === resolver
    }
    dns.timeouts = 0.5

    @host          = "localhost"
    @display_class = Net::NTP::Watch::Peers
  end

  def init_style
    if Curses.start_color then
      Curses.use_default_colors
      @colors = true

      # Curses.init_pair …
    else
    end
  end

  def new_display
    @display.stop if @display

    @display = @display_class.new self, @host
    @display.update
    @display.show
  end

  def event_loop
    loop do
      Curses.doupdate

      case key = @message.getch
      when "h"                                then
        @host = @message.get_host
        new_display
        @message.clear

      when                Curses::Key::END    then @display.scroll_bottom
      when                Curses::Key::HOME   then @display.scroll_top
      when "j",           Curses::Key::DOWN   then @display.scroll_down
      when "k",           Curses::Key::UP     then @display.scroll_up
      when " ",           Curses::Key::NPAGE  then @display.page_down
      when                Curses::Key::PPAGE  then @display.page_up

      when "q", "Q", 3, 4 then
        break # ^C, ^D
      when           26,  Curses::Key::SUSPEND then
        Curses.close_screen
        Process.kill "STOP", $$
      when nil,           Curses::Key::RESIZE then
        @display.update_size
        @message.update_size
      end
    end
  end

  def resolve addr
    case addr
    when REFCLOCK then
      addr = IPAddr.new(addr).to_i
      refclock = (addr & 0xff00) >> 8
      "%s(%d)" % [
        REFCLOCKS[refclock],
        addr & 0xff
      ]
    else
      @resolv.getname addr
    end
  rescue Resolv::ResolvError,
         Resolv::ResolvTimeout
    addr
  end

  def run
    Curses.init_screen

    init_style

    Curses.noecho
    Curses.curs_set 0 # invisible

    new_display
    @message = Net::NTP::Watch::Message.new self
    @message.clear

    trap_resume do
      event_loop
    end
  rescue Interrupt
  ensure
    Curses.close_screen
  end

  def trap_resume
    Curses.raw

    old_cont = trap "CONT" do
      Curses.doupdate
    end

    yield
  ensure
    Curses.noraw

    trap "CONT", old_cont
  end
end

require "net/ntp/watch/display"
require "net/ntp/watch/message"
require "net/ntp/watch/peers"
