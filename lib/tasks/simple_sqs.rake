namespace :simple_sqs do
  desc "Daemon that polls SQS"
  task :daemon => :environment do
    queue_url = ENV.fetch('SIMPLE_SQS_QUEUE_URL')

    Rails.logger.info "Simple SQS: started polling"

    worker = SimpleSqs::Worker.new(queue_url: queue_url)
    worker.start
  end
end
