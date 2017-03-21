require 'spec_helper'
require_relative '../../dummy_app/sqs/events/some_event'

describe SimpleSqs::Processor do
  SIMPLE_SQS_EVENTS_NAMESPACE = DummyApp::Sqs::Events

  let(:sqs) { described_class.new }
  let(:hit) {  @hit || create(:hit_aws) }
  let(:worker) {  @worker || create(:worker) }

  describe ".process_sqs_message" do
    it 'loads the appropriate class and process it' do
      DummyApp::Sqs::Events::SomeEvent.any_instance.should_receive(:process)
      described_class.new.process_sqs_message fake_sqs_message('SomeEvent', Time.now)
    end

    it 'passes the proper data to the processor' do
      event = fake_sqs_message('SomeEvent', Time.now)
      message_attrs = { approximate_receive_count: 2 }
      DummyApp::Sqs::Events::SomeEvent.should_receive(:new).with(event['Events'][0], message_attrs).and_call_original
      DummyApp::Sqs::Events::SomeEvent.any_instance.should_receive(:process)
      described_class.new.process_sqs_message event, message_attrs
    end
  end
end
