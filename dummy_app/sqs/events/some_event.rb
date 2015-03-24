module DummyApp
  module Sqs
    module Events
      class SomeEvent < SimpleSqs::Events::Base
        def process
          #
        end
      end
    end
  end
end
