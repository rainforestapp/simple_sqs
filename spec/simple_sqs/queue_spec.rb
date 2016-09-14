require 'spec_helper'

describe SimpleSqs::Queue do
  subject { described_class.new(queue_url: ENV.fetch('SIMPLE_SQS_QUEUE_URL')) }

  describe 'initialize' do
    it { expect(subject.client).to be_a(Aws::SQS::Client) }
  end

  describe '#send_message' do
    it 'builds and send the message' do
      event_name = 'YaSure'
      arguments = ['123', { ok: 'ok' }, 1]

      body = {'Events' => [
        {'EventType' => event_name,
         'EventTimestamp' => Time.now.to_s,
         'Arguments' => arguments
        }
      ]}

      expect(subject.client).to receive(:send_message).with(queue_url: ENV.fetch('SIMPLE_SQS_QUEUE_URL'), message_body: body.to_json)
      subject.send_message(event_name: event_name, arguments: arguments)
    end
  end

  describe '#approximate_number_of_messages' do
    it 'gets the number of messages' do
      expect(subject.client).to receive(:get_queue_attributes)
                                  .with(queue_url: ENV.fetch('SIMPLE_SQS_QUEUE_URL'), attribute_names: ['ApproximateNumberOfMessages'])
                                  .and_return double(attributes: { 'ApproximateNumberOfMessages' => 42 })
      expect(subject.approximate_number_of_messages).to equal 42
    end
  end
end
