class SimpleSqs::Events::Base
  attr_reader :event, :sqs_message

  def initialize(event, sqs_message = nil)
    @event = event
    @sqs_message = sqs_message
  end

  def process
    raise NotImplementedError.new
  end

  def timestamp
    Time.parse event['EventTimestamp']
  end
end
