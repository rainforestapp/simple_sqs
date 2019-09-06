require 'spec_helper'

describe SimpleSqs::Worker do
  subject { SimpleSqs::Worker.new(queue_url: ENV.fetch('SIMPLE_SQS_QUEUE_URL')) }

  describe "#receive_and_process" do
    let(:body) do
      { 'Events' => [ { } ] }
    end

    let(:message) { double(body: body.to_json, message_id: true, receipt_handle: 123, attributes: { 'ApproximateReceiveCount' => '1'}) }

    it "does not delete the message if a retry message in thrown" do
      expect(subject.client).to_not receive(:delete_message)
      expect(subject.processor).to receive(:process_sqs_message).and_raise(RuntimeError, 'meh')

      begin
        subject.send(:process, message)
      rescue Exception => e
        expect(e.message).to eq "uncaught throw :skip_delete"
      end
    end

    it "deletes the message after 5 retry" do
      expect(subject.client).to receive(:delete_message)
      expect(message).to receive(:attributes).and_return({ 'ApproximateReceiveCount' => '6' })
      expect(subject.processor).to receive(:process_sqs_message).and_raise(RuntimeError, '...')

      begin
        subject.send(:process, message)
      rescue Exception => e
        expect(e.message).to eq "uncaught throw :skip_delete"
      end
    end

    it 'passes through the approximate receive count' do
      expect(subject.processor).to receive(:process_sqs_message).with({ "Events" => [{}] }, message)
      subject.send(:process, message)
    end

    context 'when there is an error' do
      it 'raises the exception to Sentry/Raven' do
        expect(Raven).to receive(:capture_exception)

        expect {
          subject.send(:process, message)
        }.to raise_error(UncaughtThrowError)
      end
    end
  end
end
