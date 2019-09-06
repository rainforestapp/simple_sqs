require 'spec_helper'
require_relative '../../dummy_app/sqs/events/some_event'

describe SimpleSqs::Processor do
  SIMPLE_SQS_EVENTS_NAMESPACE = DummyApp::Sqs::Events

  let(:sqs) { described_class.new }
  let(:hit) {  @hit || create(:hit_aws) }
  let(:worker) {  @worker || create(:worker) }

  before do
    # Check we're not leaking ActiveRecord::Base out of the transaction test
    expect(Object.send(:const_defined?, 'ActiveRecord')).to eq(false)
  end

  describe ".process_sqs_message" do
    it 'loads the appropriate class and process it' do
      expect_any_instance_of(DummyApp::Sqs::Events::SomeEvent).to receive(:process)
      described_class.new.process_sqs_message fake_sqs_message('SomeEvent', Time.now)
    end

    it 'passes the proper data to the processor' do
      event = fake_sqs_message('SomeEvent', Time.now)
      message_attrs = { approximate_receive_count: 2 }
      expect(DummyApp::Sqs::Events::SomeEvent).to receive(:new).with(event['Events'][0], message_attrs).and_call_original
      expect_any_instance_of(DummyApp::Sqs::Events::SomeEvent).to receive(:process)
      described_class.new.process_sqs_message event, message_attrs
    end

    it 'can ignore ActiveRecord' do
      event = fake_sqs_message('SomeEvent', Time.now)
      message_attrs = { approximate_receive_count: 2 }

      ::ActiveRecord = Class.new
      ::ActiveRecord::Base = Class.new

      expect(::ActiveRecord::Base).to_not receive(:transaction)

      described_class.new.process_sqs_message(event, message_attrs, false)

      Object.send(:remove_const, 'ActiveRecord')
    end
  end
end
