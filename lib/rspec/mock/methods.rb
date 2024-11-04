# frozen_string_literal: true

module RSpec
  module Mock
    module Methods
      def rspec_mock(&block)
        return unless block_given?

        RSpec::Mocks.with_temporary_scope do
          RSpec::Mock::Context.new(self).instance_eval(&block)
        end
      end
    end
  end
end
