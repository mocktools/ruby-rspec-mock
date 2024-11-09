# frozen_string_literal: true

require 'colorize'
require 'terminal-table'

require_relative 'tracker/base'
require_relative 'tracker/flexmock'
require_relative 'tracker/rspec'
require_relative 'file_analyzer'

module RSpec
  module Mock
    module MigrationAnalytics
      class Printer
        class << self
          def call(path)
            return verify_directory(path) if ::File.directory?(path)

            verify_file(path)
          end

          private

          def verify_directory(dir_path) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
            results = []
            stats = {
              total_files: 0,
              files_with_mocks: 0,
              total_flexmock_occurrences: 0,
              total_rspec_mock_occurrences: 0,
              files_with_mixed_usage: 0
            }

            ::Dir.glob("#{dir_path}/**/*_spec.rb").each do |file|
              stats[:total_files] += 1
              result = RSpec::Mock::MigrationAnalytics::FileAnalyzer.call(file)

              next unless result[:has_mocks]
              stats[:files_with_mocks] += 1
              stats[:total_flexmock_occurrences] += result[:flexmock_count]
              stats[:total_rspec_mock_occurrences] += result[:rspec_mock_count]
              stats[:files_with_mixed_usage] += 1 if result[:has_mixed_usage]
              results << result
            end

            print_summary(results, stats)
          end

          def verify_file(file_path)
            return puts("File not found: #{file_path}".red) unless ::File.exist?(file_path)
            return puts("Not a Ruby spec file: #{file_path}".yellow) unless file_path.end_with?('_spec.rb')

            print_file_result(RSpec::Mock::MigrationAnalytics::FileAnalyzer.call(file_path))
          end

          def print_file_result(result)
            puts("\n=== Mock Usage Analysis: #{result[:file_path]} ===".blue)

            if result[:has_mocks]
              print_mock_statistics(result)
              print_locations_table('Flexmock Usage', result[:flexmock_locations]) if result[:flexmock_locations].any?
              print_locations_table('RSpec Mock Usage', result[:rspec_mock_locations]) if result[:rspec_mock_locations].any?
            else
              puts('✅ No mocking usage found'.green)
            end
          end

          def print_summary(results, stats)
            puts("\n=== Migration Status Report ===".blue)

            total_mocks = stats[:total_flexmock_occurrences] + stats[:total_rspec_mock_occurrences]
            migration_progress =
              total_mocks.zero? ? 100 : (stats[:total_rspec_mock_occurrences].to_f / total_mocks * 100).round(2)

            print_summary_table(stats, migration_progress)
            print_files_table(results) if results.any?
          end

          def print_mock_statistics(result)
            total_mocks = result[:flexmock_count] + result[:rspec_mock_count]
            migration_progress = (result[:rspec_mock_count].to_f / total_mocks * 100).round(2)
            puts(
              Terminal::Table.new do |t|
                t.add_row(['Total Mocks', total_mocks])
                t.add_row(['Flexmock Usage', result[:flexmock_count]])
                t.add_row(['RSpec Mock Usage', result[:rspec_mock_count]])
                t.add_row(['Migration Progress', "#{migration_progress}%"])
              end
            )
          end

          def print_locations_table(title, locations)
            return if locations.empty?

            puts("\n#{title}:".yellow)
            puts(
              Terminal::Table.new do |table|
                table.headings = %w[Line Type Content]
                locations.each do |loc|
                  table.add_row(create_location_row(loc))
                end
              end
            )
          end

          def create_location_row(loc)
            type_str = loc[:type].nil? ? 'unknown' : loc[:type]
            color = determine_color(loc[:type])

            [
              loc[:line_number].to_s.yellow,
              type_str.respond_to?(color) ? type_str.send(color) : type_str,
              loc[:content]
            ]
          end

          def determine_color(type)
            case type
            when 'migration mock block' then :cyan
            when 'expect mock', 'allow mock' then :blue
            when 'verifying double' then :green
            else :light_white
            end
          end

          def print_summary_table(stats, migration_progress)
            puts(
              Terminal::Table.new do |table|
                table.add_row(['Total Spec Files', stats[:total_files]])
                table.add_row(['Files with Mocks', stats[:files_with_mocks]])
                table.add_row(['Files with Mixed Usage', stats[:files_with_mixed_usage]])
                table.add_row(['Total Flexmock Occurrences', stats[:total_flexmock_occurrences]])
                table.add_row(['Total RSpec Mock Occurrences', stats[:total_rspec_mock_occurrences]])
                table.add_row(['Migration Progress', "#{migration_progress}%"])
              end
            )
          end

          def print_files_table(results)
            puts("\n=== Files Requiring Migration ===".red)
            puts(
              Terminal::Table.new do |table|
                table.headings = ['File Path', 'Flexmock Count', 'RSpec Mock Count', 'Progress']
                results.sort_by { |row| -row[:flexmock_count] }.each do |result|
                  table.add_row(create_file_row(result))
                end
              end
            )
          end

          def create_file_row(result)
            total = result[:flexmock_count] + result[:rspec_mock_count]
            progress =
              total.zero? ? 100 : (result[:rspec_mock_count].to_f / total * 100).round(2)
            [
              result[:file_path],
              result[:flexmock_count],
              result[:rspec_mock_count],
              "#{progress}%"
            ]
          end
        end
      end
    end
  end
end
