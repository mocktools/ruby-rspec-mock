# frozen_string_literal: true

module RSpec
  module Mock
    class Context
      include RSpec::Mocks::ExampleMethods
      include RSpec::Matchers

      def initialize(example_group)
        @example_group = example_group
      end

      def method_missing(method, *args, &block)
        if @example_group.respond_to?(method)
          @example_group.send(method, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method, include_private = false)
        @example_group.respond_to?(method, include_private) || super
      end
    end
  end
end
