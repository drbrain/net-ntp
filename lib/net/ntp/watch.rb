require "curses"
require "net/ntp"
require "resolv"
require "thread"

class Net::NTP::Watch

  def self.run
    watch = new
    watch.run
  end

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
  end

  def init_style
    if Curses.start_color then
      Curses.use_default_colors
      @colors = true

      # Curses.init_pair …
    else
    end
  end

  def event_loop
    loop do
      Curses.doupdate

      case key = @message.getch
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
    @resolv.getname addr
  rescue Resolv::ResolvError,
         Resolv::ResolvTimeout
    addr
  end

  def run
    Curses.init_screen

    init_style

    Curses.noecho
    Curses.curs_set 0 # invisible

    @message = Net::NTP::Watch::Message.new
    @display = Net::NTP::Watch::Peers.new self, host: "localhost"
    @display.show

    trap_resume do
      event_loop
    end
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
