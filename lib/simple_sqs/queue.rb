class SimpleSqs::Queue
  attr_reader :client

  def initialize queue_url:
    @queue_url = queue_url
    @client = Aws::SQS::Client.new(
      access_key_id: ENV.fetch('SIMPLE_SQS_PUBLIC_KEY'),
      secret_access_key: ENV.fetch('SIMPLE_SQS_SECRET_KEY'),
      region: ENV.fetch('SIMPLE_SQS_REGION')
    )
  end

  def send_message event_name:, arguments: []
    body = {'Events' => [
      {'EventType' => event_name,
       'EventTimestamp' => Time.now.to_s,
       'Arguments' => arguments
      }
    ]}

    resp = client.send_message(
      queue_url: @queue_url,
      message_body: body.to_json,
    )
  end

  def approximate_number_of_messages
    get_attribute('ApproximateNumberOfMessages')
  end

  private
  def get_attribute attribute
    resp = client.get_queue_attributes(
      attribute_names: [attribute],
      queue_url: @queue_url
    )
    resp.attributes[attribute]
  end
end
