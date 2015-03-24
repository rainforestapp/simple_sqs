class SimpleSqs::Events::Base
  attr_reader :event
  def initialize(event)
    @event = event
  end

  def process
    raise NotImplementedError.new
  end

  def timestamp
    Time.parse event['EventTimestamp']
  end
end
