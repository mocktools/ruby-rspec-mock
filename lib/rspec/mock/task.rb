# frozen_string_literal: true

require 'rake'

module RSpec
  module Mock
    class Task
      def self.load
        ::Kernel.load(::File.join(::File.dirname(__FILE__), 'tasks', 'rspec_mock.rake'))
      end
    end
  end
end
