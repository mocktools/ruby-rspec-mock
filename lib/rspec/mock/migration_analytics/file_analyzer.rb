# frozen_string_literal: true

module RSpec
  module Mock
    module MigrationAnalytics
      class FileAnalyzer
        def self.call(
          file_path,
          flexmock_tracker = RSpec::Mock::MigrationAnalytics::Tracker::Flexmock.new,
          rspec_tracker = RSpec::Mock::MigrationAnalytics::Tracker::Rspec.new
        )
          new(file_path, flexmock_tracker, rspec_tracker).call
        end

        def initialize(file_path, flexmock_tracker, rspec_tracker)
          @file_path = file_path
          @flexmock_tracker = flexmock_tracker
          @rspec_tracker = rspec_tracker
        end

        def call
          build_analytics
          generate_report
        end

        private

        attr_reader :file_path, :flexmock_tracker, :rspec_tracker

        def build_analytics
          ::File.read(file_path).split("\n").each_with_index do |line, index|
            line_number = index + 1
            flexmock_tracker.scan_line(line, line_number)
            rspec_tracker.scan_line(line, line_number)
          end
        end

        %i[flexmock_tracker rspec_tracker].each do |method_name|
          target_method_name = :"#{method_name}_locations"
          define_method(target_method_name) { send(method_name).locations }
          define_method(:"#{target_method_name}_any?") { send(target_method_name).any? }
        end

        def generate_report
          {
            file_path: file_path,
            flexmock_count: flexmock_tracker_locations.size,
            rspec_mock_count: rspec_tracker_locations.size,
            flexmock_locations: flexmock_tracker_locations,
            rspec_mock_locations: rspec_tracker_locations,
            has_mocks: flexmock_tracker_locations_any? || rspec_tracker_locations_any?,
            has_mixed_usage: flexmock_tracker_locations_any? && rspec_tracker_locations_any?
          }
        end
      end
    end
  end
end
