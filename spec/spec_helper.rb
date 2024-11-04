# frozen_string_literal: true

rspec_custom = ::File.join(::File.dirname(__FILE__), 'support/**/*.rb')
::Dir[::File.expand_path(rspec_custom)].sort.each { |file| require file unless file[/\A.+_spec\.rb\z/] }

require_relative '../lib/rspec/mock'

RSpec.configure do |config|
  config.expect_with(:rspec) do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end

  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.order = :random

  config.rspec_mock do |mock|
    mock.verify_partial_doubles = true
  end

  config.include RSpec::Mock::Methods

  ::Kernel.srand(config.seed)
end
