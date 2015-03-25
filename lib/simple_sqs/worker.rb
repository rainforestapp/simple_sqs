class SimpleSqs::Worker
  attr_reader :client, :processor

  def initialize queue_url:
    @queue_url = queue_url
    @client = Aws::SQS::Client.new(
      access_key_id: ENV.fetch('SIMPLE_SQS_PUBLIC_KEY'),
      secret_access_key: ENV.fetch('SIMPLE_SQS_SECRET_KEY'),
      region: ENV.fetch('SIMPLE_SQS_REGION')
    )
    @processor = SimpleSqs::Processor.new
    @poller = Aws::SQS::QueuePoller.new(@queue_url, { client: @client })
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

    @poller.poll(visibility_timeout: 5) do |message|
      process(message)
    end
  end

  private
  def stop_polling
    logger.info "Stopping SQS polling"
    throw :stop_polling
  end

  def process(message)
    json_message = MultiJson.decode(message.body)
    begin
      processor.process_sqs_message json_message
    rescue Exception => e
      logger.error "SQS: #{message.message_id}\t#{e.message}\t#{e.backtrace}"
      Librato.increment("#{SIMPLE_SQS_LIBRATO_PREFIX}.sqs.error")
      handle_message_error(message, exception: e)
    end
  end

  def handle_message_error(message, exception: nil)
    if message.attributes['ApproximateReceiveCount'].to_i > ENV.fetch('MAX_SQS_MESSAGE_RETRY', 5)
      logger.error "Deleting SQS message after multiple failures. #{message.body} #{exception}"
      Librato.increment("#{SIMPLE_SQS_LIBRATO_PREFIX}.sqs.fatal_error")
      client.delete_message(
        queue_url: @queue_url,
        receipt_handle: message.receipt_handle)
    else
      # The `poll` loop usually deletes the messages in SQS by default, but we want to
      # retry to run those as they errored out.
      throw :skip_delete
    end
  end

  def options
    @options ||= {
      queue_url: @queue_url,
      visibility_timeout: 10,
      wait_time_seconds: 15,
      attribute_names: [:all]
    }.freeze
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end
end
