# frozen_string_literal: true

require 'set'

module RSpec
  module Mock
    module MigrationAnalytics
      module Tracker
        class Flexmock < RSpec::Mock::MigrationAnalytics::Tracker::Base
          PATTERNS = {
            direct_call: /\bFlexMock\./,
            helper_call: /\bflexmock\s*\(/,
            new_instances: /\bflexmock\s*\([^)]+\)\.new_instances\s*do\s*\|/,
            var_assignment: /(\w+)\s*=\s*flexmock\s*\(/,
            nested_mock: /\b(?:m|mock)\.should_receive(?:\([^)]*\))?/,
            block_start: /\bflexmock\s*\([^)]+\)\s*do\s*\|/,
            expectation_var: /(\w+)\s*=\s*flexmock\s*\([^)]*\)\.should_receive/,
            single_line_block: /^(it|before)\s*{.*flexmock\(/,
            should_receive: /flexmock\([^)]+\)\.should_receive/,
            chained_should_receive: /\b(?:mock|m)\.should_receive\([^)]*\)(?:\.(and_return|with|once|twice|never|returns|and_raise))+/,
            block_param: /\bflexmock\s*\([^)]+\)\s*do\s*\|([^|]+)\|/,
            chaining: [
              /\.should_receive/,
              /\.and_return/,
              /\.once/,
              /\.twice/,
              /\.with/,
              /\.returns/,
              /\.and_raise/
            ],
            pure_chain: /\b(?:should_receive\([^)]*\)(?:\.(and_return|with|once|twice|never|returns|and_raise))+)/,
            flexmock_in_block: /\b(it|before|let)\s*{[^}]*flexmock/,
            flexmock_in_do_block: /\b(it|before|let)\s+do.*flexmock/,
            block_end: /\bend\b|\}/,
            expectation_assignment: /(\w+)\s*=\s*.*should_receive/,
            direct_should_receive: /flexmock\([^)]*\)\.should_receive/,
            var_reference: /\b%s\b/,
            mock_chain: /\.should_receive|\.(and_return|with|once|twice|never|returns|and_raise)/,
            var_boundary_template: '\b%s\b',
            should_receive_chain: /\.should_receive/,
            method_chain: /\.(and_return|with|once|twice|never|returns|and_raise)/
          }.freeze

          attr_reader :flexmock_vars, :flexmock_expectations

          def initialize
            @flexmock_vars = ::Set.new
            @flexmock_expectations = ::Set.new
            super
          end

          def scan_line(line, line_number)
            return if line.strip.empty? || line.strip.start_with?('#')

            track_flexmock_blocks(line)
            track_flexmock_vars(line)

            return unless flexmock_line?(line)
            locations << {
              line_number: line_number,
              content: line.strip,
              type: determine_flexmock_type(line)
            }
          end

          private

          def flexmock_line?(line)
            stripped_line = line.strip
            return false if stripped_line.empty? || stripped_line.start_with?('#')

            # Direct flexmock
            return true if direct_flexmock?(stripped_line)

            # Variable-based flexmock
            return true if flexmock_var_reference?(stripped_line)

            # Block-based flexmock
            return true if in_mock_block? && mock_chain?(stripped_line)

            false
          end

          def determine_flexmock_type(line)
            stripped_line = line.strip
            case stripped_line
            when RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:new_instances] then 'flexmock new_instances block'
            when RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:block_start] then 'flexmock block'
            when RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:should_receive] then 'flexmock expectation'
            when RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:chained_should_receive] then 'flexmock chained should'
            when RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:nested_mock] then 'nested flexmock'
            when RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:pure_chain] then 'flexmock chain'
            else 'flexmock related'
            end
          end

          def direct_flexmock?(line)
            case line
            when RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:direct_call],
                RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:helper_call],
                RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:new_instances],
                RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:should_receive],
                RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:expectation_var],
                RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:flexmock_in_block],
                RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:flexmock_in_do_block]
              true
            else
              false
            end
          end

          def mock_chain?(line)
            RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:chaining].any? { |pattern| line.match?(pattern) }
          end

          def track_flexmock_vars(line)
            case line.strip
            when RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:var_assignment],
                RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:block_param],
                RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:expectation_assignment]
              flexmock_vars.add(::Regexp.last_match(1).strip)
            end
          end

          def track_flexmock_blocks(line)
            case line.strip
            when RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:block_start],
                RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:new_instances],
                RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:flexmock_in_do_block]
              self.in_mock_block = true
              self.block_level += 1
            when RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:block_end]
              if in_mock_block?
                self.block_level -= 1
                self.in_mock_block = false if block_level.negative?
              end
            end
          end

          def flexmock_var_reference?(line)
            return false if flexmock_vars.empty?

            flexmock_vars.any? do |var|
              regex = ::Regexp.new(RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:var_boundary_template] % var)
              line.match?(regex) && (
                line.match?(RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:should_receive_chain]) ||
                line.match?(RSpec::Mock::MigrationAnalytics::Tracker::Flexmock::PATTERNS[:method_chain])
              )
            end
          end
        end
      end
    end
  end
end
