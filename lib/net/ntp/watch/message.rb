class Net::NTP::Watch::Message < Curses::Window

  ##
  # Creates a new Message instance that will sit at the bottom line of the
  # screen

  def initialize watch
    super 1, Curses.cols, Curses.lines - 1, 0

    @watch = watch

    keypad true
  end

  ##
  # Clears the message window

  def clear
    super

    if name = @watch.display&.name then
      setpos 0, maxx - name.size - @watch.host.size - 1
      attron Curses::A_BOLD
      addstr name
      attroff Curses::A_BOLD
      addstr " "
      addstr @watch.host
    end

    setpos 0, 0

    noutrefresh
  end

  ##
  # Displays the error +message+ and flashes the screen

  def error message
    clear
    addstr message
    refresh
    Curses.flash
  end

  def get_host
    host = prompt "host"
    host.strip!

    return @watch.host if host.empty?

    host
  end

  ##
  # Displays a prompt on the screen and returns the input given

  def prompt name
    clear

    attron Curses::A_BOLD do
      addstr "#{name}> "
    end

    Curses.echo

    return getstr
  ensure
    Curses.noecho
    clear
  end

  ##
  # Shows the informational +message+ on the screen

  def show message
    clear
    addstr message
    noutrefresh
  end

  ##
  # Updates the size of the window

  def update_size
    move Curses.lines - 1, 0
    resize 1, Curses.cols

    clear
  end
end
