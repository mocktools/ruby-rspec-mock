# frozen_string_literal: true

namespace :rspec_mock do
  namespace :migration_analytics do
    desc 'Analyze Flexmock usage and track migration progress to RSpec mocks'
    # :nocov:
    task :flexmock do
      require 'rspec/mock/migration_analytics/printer'

      path = ::ARGV[1] || 'spec'
      puts("\n🔍 Analyzing Flexmock usage in: #{path}")
      RSpec::Mock::MigrationAnalytics::Printer.call(path)
    end
    # :nocov:
  end
end
