class SimpleSqs::Worker
  attr_reader :client, :processor

  # Allow another worker to get the message after this long. Suggest 25%-50% more
  # than your average job
  VISIBILITY_TIMEOUT = ENV.fetch('SIMPLE_SQS_VISABILITY_TIMEOUT', 15).to_i.freeze

  # Set to false if you're using a redrive policy on your queue.
  DELETE_AFTER_MAX_RETRY = (ENV.fetch('DELETE_AFTER_MAX_RETRY', 'true').downcase == 'true').freeze

  # If DELETE_AFTER_MAX_RETRY enabled, delete after this many retrys
  MAX_RETRY = ENV.fetch('MAX_SQS_MESSAGE_RETRY', 5).to_i.freeze

  def initialize queue_url:
    @queue_url = queue_url
    @client = Aws::SQS::Client.new(
      access_key_id: ENV.fetch('SIMPLE_SQS_PUBLIC_KEY'),
      secret_access_key: ENV.fetch('SIMPLE_SQS_SECRET_KEY'),
      region: ENV.fetch('SIMPLE_SQS_REGION')
    )
    @processor = SimpleSqs::Processor.new
    @poller = Aws::SQS::QueuePoller.new(@queue_url, {client: @client})
    @transaction = (ENV.fetch('SIMPLE_SQS_NO_AR_TRANSACTION', true) == true)
  end

  def transaction?
    @transaction
  end

  def start
    logger.info 'Starting SQS polling'
    receive_and_process
  end

  def receive_and_process
    @poller.before_request do |stats|
      trap "INT", -> (*args) { stop_polling }
      trap "TERM", -> (*args) { stop_polling }
    end

    @poller.poll(visibility_timeout: VISIBILITY_TIMEOUT) do |message|
      process(message)
    end
  end

  private
  def stop_polling
    logger.info "Stopping SQS polling"
    throw :stop_polling
  end

  def process(message)
    json_message_body = MultiJson.decode(message.body)
    begin
      processor.process_sqs_message(json_message_body, message, transaction?)
    rescue Exception => e
      logger.error "SQS: #{message.message_id}\t#{e.message}\t#{e.backtrace}"
      Librato.increment('sqs.error')
      handle_message_error(message, exception: e)
    end
  end

  def handle_message_error(message, exception: nil)
    if exception
      Raven.capture_exception(exception, extra: {parameters: message, cgi_data: ENV})
    end

    if DELETE_AFTER_MAX_RETRY && message.attributes['ApproximateReceiveCount'].to_i > MAX_RETRY
      logger.error "Deleting SQS message after multiple failures. #{message.body} #{exception}"
      Librato.increment('sqs.fatal_error')
      client.delete_message(queue_url: @queue_url, receipt_handle: message.receipt_handle)
    else
      # The `poll` loop usually deletes the messages in SQS by default, but we want to
      # retry to run those as they errored out.
      throw :skip_delete
    end
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end
end
