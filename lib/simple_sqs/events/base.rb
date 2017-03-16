class SimpleSqs::Events::Base
  attr_reader :event, :message_attributes

  def initialize(event, message_attributes = {})
    @event = event
    @message_attributes = {}
  end

  def process
    raise NotImplementedError.new
  end

  def timestamp
    Time.parse event['EventTimestamp']
  end
end
