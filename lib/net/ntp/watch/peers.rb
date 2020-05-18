require "ipaddr"

class Net::NTP::Watch::Peers < Net::NTP::Watch::Display

  MULTICAST_V4 = IPAddr.new "224.0.0.0/4"
  MULTICAST_V6 = IPAddr.new "ff00::/8"
  REFCLOCK     = IPAddr.new "127.127.0.0/16"
  UNSPEC       = IPAddr.new "0.0.0.0"

  def initialize watch, host:, port: 123
    super watch

    @ntp    = Net::NTP.new host, port: port
    @peers  = nil
    @update = update
  end

  def show
    super do
      header = " %16s %16s st t when poll reach  delay   offset  jitter\n" % [
        "remote".center(16),
        "refid".center(16),
      ]
      attron Curses::A_BOLD
      addstr header
      addstr "═" * maxx
      attroff Curses::A_BOLD

      break unless @peers

      @peers.each do |peer|
        addstr peer
        addstr "\n"
      end
    end
  end

  def update
    Thread.new do
      Thread.current.abort_on_exception = true

      loop do
        update_peers

        show

        Curses.doupdate

        sleep 2
      end
    end
  end

  def update_peers
    @peers = @ntp.readstat.sort_by(&:association_id).map { |stat|
      id = stat.association_id

      vars = @ntp.readvar id

      tally = Net::NTP::PeerStatus::TALLY[stat.selection]

      remote = vars.srchost
      remote ||= @watch.resolve vars.srcadr

      refid  =
        case vars.stratum
        when 0, 1, 16 then
          ".#{vars.refid}."
        else
          @watch.resolve vars.refid
        end

      type =
        case vars.hmode
        when 6 then "b"
        when 5 then
          case vars.srcaddr
          when MULTICAST_V4, MULTICAST_V6 then
            "M"
          else
            "B"
          end
        when 3 then
          case vars.srcadr
          when REFCLOCK then
            "l"
          when UNSPEC then
            "p"
          when MULTICAST_V4, MULTICAST_V6 then
            "a"
          else
            "u"
          end
        when 1 then
          "s"
        when 2 then
          "S"
        end

      lasttime =
        if vars.rec.to_i != Net::NTP::Conversion::TIME_T_OFFSET then
          vars.rec
        elsif vars.reftime.to_i != Net::NTP::Conversion::TIME_T_OFFSET then
          vars.reftime
        else
          Time.at(-Net::NTP::TIME_T_OFFSET)
        end

      updated =
        if lasttime.to_i == -Net::NTP::Conversion::TIME_T_OFFSET then
          "-"
        else
          (Time.now - lasttime).to_i
        end

      poll = 1 << [vars.ppoll, vars.hpoll].min

      "%c%16.16s %-16.16s %2d %c %4.4s %4d  %3o %7.3f %+8.3f %7.3f" % [
        tally,
        remote,
        refid,
        vars.stratum,
        type,
        updated,
        poll,
        vars.reach,
        vars.delay,
        vars.offset,
        vars.jitter,
      ]
    }
  end
end
