class Net::NTP::Watch::Sysinfo < Net::NTP::Watch::Display

  def initialize watch, host
    super watch

    @ntp     = Net::NTP.new host
    @sysinfo = nil
  end

  def show
    super do
      addstr @sysinfo
    end
  end

  def update
    super do
      update_sysinfo
    end
  end

  def update_sysinfo
    vars = @ntp.sysinfo

    host, port = vars.peeradr.split ":"
    host = @watch.resolve host

    sysinfo = []
    sysinfo << "system peer:        #{host}:#{port}"
    sysinfo << "system peer mode:   #{vars.peermode}"
    sysinfo << "leap indicator:     %0.2o" % vars.leap
    sysinfo << "stratum:            #{vars.stratum}"
    sysinfo << "log2 precision:     #{vars.precision}"
    sysinfo << "root delay:         #{vars.rootdelay}"
    sysinfo << "root dispersion:    #{vars.rootdisp}"
    sysinfo << "reference ID:       #{vars.refid}"
    sysinfo << "reference time:     #{vars.reftime}"
    sysinfo << "system jitter:      #{vars.sys_jitter}"
    sysinfo << "clock jitter:       #{vars.clk_jitter}"
    sysinfo << "clock wander:       #{vars.clk_wander}"
    sysinfo << "broadcast delay:    #{vars.bcastdelay}"
    sysinfo << "symm. auth. delay:  #{vars.authdelay}"

    @sysinfo = sysinfo.join "\n"
  end
end
