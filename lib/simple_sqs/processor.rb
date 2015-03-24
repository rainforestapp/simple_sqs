#
# Simple SQS
#
# This is used to process SQS notifications
#
require 'logger'

class SimpleSqs::Processor
  def process_sqs_message sqs_message
    if Object.const_defined?("ActiveRecord")
      ActiveRecord::Base.transaction do
        sqs_message['Events'].each do |event|
          process event
        end
      end
    else
      sqs_message['Events'].each do |event|
        process event
      end
    end
  end

  private
  def process event
    logger.debug "Processing SQS event #{event.inspect}"
    Librato.timing("sqs.process", source: event['EventType']) do
      klass = SIMPLE_SQS_EVENTS_NAMESPACE.const_get(event['EventType'])
      sqs_event = klass.new(event.freeze)

      lag = ((Time.now - sqs_event.timestamp) * 1000).ceil
      Librato.measure("sqs.lag", lag, source: event['EventType'])
      Librato.increment("sqs.events", source: event['EventType'])

      sqs_event.process
    end
  rescue NameError => e
    Raven.capture_exception(e, extra: {parameters: event, cgi_data: ENV})
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end
end
