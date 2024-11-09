# frozen_string_literal: true

module RSpec
  module Mock
    class Railtie < ::Rails::Railtie
      rake_tasks do
        load(::File.join(::File.dirname(__FILE__), 'tasks', 'rspec_mock.rake'))
      end
    end
  end
end
