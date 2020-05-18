class Net::NTP::Watch::Display < Curses::Pad
  def initialize watch
    super Curses.lines - 1, Curses.cols

    @watch   = watch
    @message = watch.message

    clear
  end

  def clear
    @current_row = 0

    setpos 0, 0
    resize 0, Curses.cols

    super

    noutrefresh
  end

  alias rows maxy

  def max_row
    maxy - Curses.lines + 1
  end

  def page_down
    @current_row += Curses.lines - 1

    noutrefresh
  end

  def page_up
    @current_row -= Curses.lines - 1

    noutrefresh
  end

  def show
    clear

    yield

    noutrefresh
  end

  def stop
    clear

    refresh
  end

  def screen_position
    @current_row = 0       if @current_row < 0
    @current_row = max_row if @current_row > max_row

    [@current_row, 0, 0, 0, Curses.lines - 2, Curses.cols]
  end

  def scroll_bottom
    @current_row = max_row

    noutrefresh
  end

  def scroll_down
    @current_row += 1

    noutrefresh
  end

  def scroll_top
    @current_row = 0

    noutrefresh
  end

  def scroll_up
    @current_row -= 1

    noutrefresh
  end

  def noutrefresh
    super(*screen_position)
  end

  def refresh
    super(*screen_position)
  end

  def update_size
    resize Curses.lines - 1, Curses.cols

    clear
  end
end

