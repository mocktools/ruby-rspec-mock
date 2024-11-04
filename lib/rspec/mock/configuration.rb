# frozen_string_literal: true

module RSpec
  module Mock
    module Configuration
      def rspec_mock
        RSpec::Mocks.configuration.tap do |config|
          yield config if block_given?
        end
      end
    end
  end
end
