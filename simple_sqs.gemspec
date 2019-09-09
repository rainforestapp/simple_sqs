# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simple_sqs/version'

Gem::Specification.new do |spec|
  spec.name          = "simple_sqs"
  spec.version       = SimpleSqs::VERSION
  spec.authors       = ["Jean-Philippe Boily"]
  spec.email         = ["j@jipi.ca"]

  spec.summary       = 'Opinionated but Simple SQS wrapper.'
  spec.homepage      = 'https://github.com/rainforestapp/simple_sqs'
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk"
  spec.add_dependency "librato-rails"
  spec.add_dependency "sentry-raven"
  spec.add_dependency "multi_json"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "byebug"
end
