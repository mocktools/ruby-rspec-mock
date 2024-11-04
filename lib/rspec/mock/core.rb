# frozen_string_literal: true

require 'rspec/core'
require 'rspec/mocks'

module RSpec
  module Mock
    require_relative 'configuration'
    require_relative 'context'
    require_relative 'methods'
    require_relative 'version'
  end

  module Core
    require_relative '../core/configuration'
  end
end
