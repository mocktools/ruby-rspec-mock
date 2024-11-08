# frozen_string_literal: true

module RSpec
  module Mock
    module MigrationAnalytics
      module Tracker
        class Rspec < RSpec::Mock::MigrationAnalytics::Tracker::Base
          PATTERNS = {
            block_start: /\b(rspec_mock)\s+(?:do|\{)/,
            block_end: /(?:\}|\bend\b)/,
            single_line_block: /rspec_mock\s*{/,
            expect: /\bexpect\b/,
            allow: /\ballow\b/,
            have_received: /\bhave_received\b/,
            mock_chain: /\.(to_receive|to\s+receive|and_return|and_raise)/,
            mock_related: /\b(?:
              expect|
              allow|
              receive|
              and_return|
              and_raise|
              have_received|
              instance_double|
              class_double|
              object_double|
              double
            )\b/x,
            end_brace: /\}\s*$/,
            empty_or_comment: /^\s*(?:#.*)?$/
          }.freeze

          def scan_line(line, line_number)
            return if line.strip.empty? || line.strip.start_with?('#')

            line.split(';').each do |statement|
              stripped_statement = statement.strip
              track_rspec_mock_blocks(stripped_statement)
              track_rspec_mock_usage(stripped_statement, line_number)
            end
          end

          private

          def mock_related?(line)
            line.match?(RSpec::Mock::MigrationAnalytics::Tracker::Rspec::PATTERNS[:mock_related])
          end

          def determine_rspec_mock_type(line)
            case line
            when RSpec::Mock::MigrationAnalytics::Tracker::Rspec::PATTERNS[:have_received] then 'spy verification'
            when RSpec::Mock::MigrationAnalytics::Tracker::Rspec::PATTERNS[:expect] then 'expect mock'
            when RSpec::Mock::MigrationAnalytics::Tracker::Rspec::PATTERNS[:allow] then 'allow mock'
            when RSpec::Mock::MigrationAnalytics::Tracker::Rspec::PATTERNS[:mock_chain] then 'mock chain'
            else 'rspec mock related'
            end
          end

          def track_rspec_mock_blocks(line)
            case line
            when RSpec::Mock::MigrationAnalytics::Tracker::Rspec::PATTERNS[:single_line_block]
              self.in_mock_block = true
            when RSpec::Mock::MigrationAnalytics::Tracker::Rspec::PATTERNS[:block_start]
              self.in_mock_block = true
              self.block_level += 1
            when RSpec::Mock::MigrationAnalytics::Tracker::Rspec::PATTERNS[:block_end]
              self.block_level -= 1
              self.in_mock_block = false if block_level.zero?
            end

            # Reset block state for single-line blocks
            self.in_mock_block = false if line.end_with?('}')
          end

          def track_rspec_mock_usage(line, line_number)
            return unless (in_mock_block? || line.match?(RSpec::Mock::MigrationAnalytics::Tracker::Rspec::PATTERNS[:single_line_block])) &&
                          mock_related?(line)

            locations << {
              line_number: line_number,
              content: line,
              type: determine_rspec_mock_type(line)
            }
          end
        end
      end
    end
  end
end
