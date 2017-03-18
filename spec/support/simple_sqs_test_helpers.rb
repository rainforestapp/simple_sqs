require 'json'
module SimpleSqsHelpers
  def fake_sqs_message eventtype, ts, *args
    doc = {}
    doc['Events'] = []

    event = {}
    event['EventType'] = eventtype
    event['EventTimestamp'] = ts.strftime '%Y-%m-%dT%H:%M:%SZ'

    event['Arguments'] = args

    doc['Events'] << event

    JSON.parse doc.to_json
  end
end

RSpec.configure do |config|
  config.include SimpleSqsHelpers
end

ENV['SIMPLE_SQS_QUEUE_URL'] ||= 'fake'
ENV['SIMPLE_SQS_PUBLIC_KEY'] ||= 'fake'
ENV['SIMPLE_SQS_SECRET_KEY'] ||= 'fake'
ENV['SIMPLE_SQS_REGION'] ||= 'us-east-1'
