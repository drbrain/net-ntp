##
# Status fields for an NTP peer

class Net::NTP::PeerStatus

  ##
  # Maps #event_code to a readable event

  EVENT_CODES = {
    1 => "peer IP error",
    4 => "peer reachable",
  }

  ##
  # Maps #selection to a readable status

  SELECTIONS = {
    0 => "reject",
    1 => "false ticker",
    2 => "excess",
    3 => "outlier",
    4 => "candidate",
    5 => "backup",
    6 => "system peer",
    7 => "pps peer",
  }


  ##
  # Peer association ID

  attr_reader :association_id

  ##
  # True if authentication is enabled

  attr_reader :authenable

  ##
  # True if the peer authentication is ok

  attr_reader :authentic

  ##
  # True if the peer is configured

  attr_reader :configured

  ##
  # True if the peer is reachable

  attr_reader :reach

  ##
  # Value of the reserved bit

  attr_reader :reserved

  ##
  # Peer selection status

  attr_reader :selection

  ##
  # Peer event count

  attr_reader :event_count

  ##
  # Peer event code

  attr_reader :event_code

  ##
  # Create a new peer status for +association_id+

  def initialize association_id
    @association_id = association_id
  end

  ##
  # Extracts peer status fields from +data+

  def unpack data
    @configured  =  data >> 15        == 1
    @authenable  = (data >> 14) & 0b1 == 1
    @authentic   = (data >> 13) & 0b1 == 1
    @reach       = (data >> 12) & 0b1 == 1
    @reserved    = (data >> 11) & 0b1
    @selection   = (data >>  8) & 0b111
    @event_count = (data >>  4) & 0b1111
    @event_code  =  data        & 0b1111
  end

  def pretty_print q # :nodoc:
    q.group 2, "[PeerStatus", "]" do
      q.fill_breakable

      q.text "assoc_id:"
      q.fill_breakable
      q.pp @association_id
      q.comma_breakable

      if @reach then
        q.text "selection:"
        q.fill_breakable
        q.pp SELECTIONS.fetch @selection, @selections
        q.comma_breakable

        q.text "event:"
        q.fill_breakable
        q.pp EVENT_CODES.fetch @event_code, @event_code
        q.comma_breakable

        q.text "count:"
        q.fill_breakable
        q.pp @event_count
      else
        q.text "unreachable"
      end
    end
  end
end
