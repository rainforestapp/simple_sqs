require 'spec_helper'

describe SimpleSqs::Worker do
  subject { SimpleSqs::Worker.new(queue_url: ENV.fetch('SIMPLE_SQS_QUEUE_URL')) }

  describe "#receive_and_process" do
    let(:body) do
      { 'Events' => [ { } ] }
    end

    let(:message) { double(body: body.to_json, message_id: true, receipt_handle: 123, attributes: { 'ApproximateReceiveCount' => '1'}) }

    it "does not delete the message if a retry message in thrown" do
      subject.client.should_not_receive(:delete_message)
      subject.processor.stub(:process_sqs_message) do
        raise 'meh'
      end

      begin
        subject.send(:process, message)
      rescue Exception => e
        expect(e.message).to eq "uncaught throw :skip_delete"
      end
    end

    it "deletes the message after 5 retry" do
      subject.client.should_receive(:delete_message)
      message.stub(:attributes).and_return({ 'ApproximateReceiveCount' => '6' })
      subject.processor.stub(:process_sqs_message) do
        raise '...'
      end

      begin
        subject.send(:process, message)
      rescue Exception => e
        expect(e.message).to eq "uncaught throw :skip_delete"
      end
    end
  end
end
