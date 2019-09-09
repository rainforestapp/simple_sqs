# SimpleSqs

[![Build Status](https://travis-ci.org/rainforestapp/simple_sqs.svg)](https://travis-ci.org/rainforestapp/simple_sqs)

SimpleSqs is a super simple abstraction of SQS. You can have a daemon polling and running jobs for messages, and enqueue some messages too. It was developed by Rainforest QA, a [web app testing](https://www.rainforestqa.com/product/web-app-testing/) platform.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'simple_sqs'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simple_sqs

### Configuration

The way that SimpleSqs works is that you will enqueue messages with an `event_name`, this should be the name of a class in your app consuming the messages. You need to setup the namespace for it, just like this:

```ruby
# config/initializers/simple_sqs.rb <- if you are using Rails, as an example
SIMPLE_SQS_EVENTS_NAMESPACE = MyApp::Sqs::Events
```

Some more configuration needed:

```
export SIMPLE_SQS_PUBLIC_KEY=...
export SIMPLE_SQS_SECRET_KEY=...
export SIMPLE_SQS_REGION=...
```

### ActiveRecord

If your project uses ActiveRecord, the processing of messages will take place in a transaction. Stop this behaviour by setting the environment variable `SIMPLE_SQS_NO_AR_TRANSACTION` with any value:

```
export SIMPLE_SQS_NO_AR_TRANSACTION=true
```

### Librato prefix

If you have multiple apps using SimpleSqs that all logs to the same Librato account, it is higly suggested to configure each app with a [custom prefix](https://github.com/librato/librato-rails#custom-prefixes).

### Rake task

To be able to use the polling included in SimpleSqs, you can just add this to your Rakefile:

```ruby
spec = Gem::Specification.find_by_name 'simple_sqs'
load "#{spec.gem_dir}/lib/tasks/simple_sqs.rake"
```

And then start this rake task to start polling: `bundle exec rake simple_sqs:daemon`

## Usage

You can have a daemon on Heroku, as an example, by puttin a line like this in your `Procfile`:

```
sqs: env SIMPLE_SQS_QUEUE_URL=http://.... bundle exec rake simple_sqs:daemon
```

To enqueue new messages:

```ruby
q = SimpleSqs::Queue.new(queue_url: "https://sqs.us-east-1.amazonaws.com...../my-queue-name")
q.send_message(event_name: 'MyEvent', arguments: ['ok', 1])
```

### Sample job

```ruby
class MyApp::Sqs::Events::MyEvent < SimpleSqs::Events::Base
  def process
    arguments = event['Arguments']
    # do whatever you want here my friend!
  end
end

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/simple_sqs/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
