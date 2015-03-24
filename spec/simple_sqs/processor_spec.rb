require 'spec_helper'
require_relative '../../dummy_app/sqs/events/some_event'

describe SimpleSqs::Processor do
  let(:sqs) { described_class.new }
  let(:hit) {  @hit || create(:hit_aws) }
  let(:worker) {  @worker || create(:worker) }

  describe ".process_sqs_message" do
    it 'loads the appropriate class and process it' do
      SimpleSqs::EVENTS_NAMESPACE = DummyApp::Sqs::Events
      DummyApp::Sqs::Events::SomeEvent.any_instance.should_receive(:process)
      described_class.new.process_sqs_message fake_sqs_message('SomeEvent', Time.now)
    end
  end
end
