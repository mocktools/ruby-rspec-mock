# frozen_string_literal: true

require 'rspec/core'
require 'rspec/mocks'

module RSpec
  module Mock
    module MigrationAnalytics
      module Tracker
        require_relative 'migration_analytics/tracker/base'
        require_relative 'migration_analytics/tracker/flexmock'
        require_relative 'migration_analytics/tracker/rspec'
      end

      require_relative 'migration_analytics/file_analyzer'
      require_relative 'migration_analytics/printer'
    end

    require_relative 'configuration'
    require_relative 'context'
    require_relative 'methods'
    require_relative 'version'

    require_relative(defined?(::Rails) ? 'railtie' : 'task')
  end

  module Core
    require_relative '../core/configuration'
  end
end
