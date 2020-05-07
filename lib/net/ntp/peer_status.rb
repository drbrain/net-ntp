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
    0 => "rejected",
    3 => "passed candidate checks",
    4 => "passed outlyer checks",
    6 => "current synchonization source",
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
  # Peer event counter

  attr_reader :event_counter

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
    @configured    =  data >> 15        == 1
    @authenable    = (data >> 14) & 0b1 == 1
    @authentic     = (data >> 13) & 0b1 == 1
    @reach         = (data >> 12) & 0b1 == 1
    @reserved      = (data >> 11) & 0b1
    @selection     = (data >>  8) & 0b111
    @event_counter = (data >>  4) & 0b1111
    @event_code    =  data        & 0b1111
  end
end
