#
# Simple SQS
#
# This is used to process SQS notifications
#
require 'logger'

class SimpleSqs::Processor
  def process_sqs_message json_message_body, sqs_message = nil
    if Object.const_defined?("ActiveRecord")
      ActiveRecord::Base.transaction do
        json_message_body['Events'].each do |event|
          process event, sqs_message
        end
      end
    else
      json_message_body['Events'].each do |event|
        process event, sqs_message
      end
    end
  end

  private
  def process event, sqs_message
    logger.debug "Processing SQS event #{event.inspect}, raw message: #{sqs_message.inspect}"
    Librato.timing("sqs.process", source: event['EventType']) do
      klass = SIMPLE_SQS_EVENTS_NAMESPACE.const_get(event['EventType'])
      sqs_event = klass.new(event.freeze, sqs_message)

      lag = ((Time.now - sqs_event.timestamp) * 1000).ceil
      Librato.measure("sqs.lag", lag, source: event['EventType'])
      Librato.increment("sqs.events", source: event['EventType'])

      sqs_event.process
    end
  rescue NameError => e
    Raven.capture_exception(e, extra: {parameters: event, cgi_data: ENV})
    logger.error e
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end
end
