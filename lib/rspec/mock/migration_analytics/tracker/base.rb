# frozen_string_literal: true

module RSpec
  module Mock
    module MigrationAnalytics
      module Tracker
        class Base
          attr_reader :locations
          attr_accessor :in_mock_block, :block_level

          alias in_mock_block? in_mock_block

          def initialize
            @locations = []
            @block_level = 0
            @in_mock_block = false
          end

          def scan_line; end
        end
      end
    end
  end
end
