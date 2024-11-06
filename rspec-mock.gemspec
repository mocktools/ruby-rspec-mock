# frozen_string_literal: true

require_relative 'lib/rspec/mock/version'

Gem::Specification.new do |spec|
  spec.name          = 'rspec-mock'
  spec.version       = RSpec::Mock::VERSION
  spec.authors       = ['Vladislav Trotsenko']
  spec.email         = %w[admin@bestweb.com.ua]

  spec.summary       = %(RSpec::Mock - seamless migration from third-party mocks to RSpec built-in mocking framework)
  spec.description   = %(RSpec::Mock - seamless migration from third-party mocks to RSpec built-in mocking framework.)

  spec.homepage      = 'https://github.com/mocktools/ruby-rspec-mock'
  spec.license       = 'MIT'

  spec.metadata = {
    'homepage_uri' => 'https://github.com/mocktools/ruby-rspec-mock',
    'changelog_uri' => 'https://github.com/mocktools/ruby-rspec-mock/blob/master/CHANGELOG.md',
    'source_code_uri' => 'https://github.com/mocktools/ruby-rspec-mock',
    'documentation_uri' => 'https://github.com/mocktools/ruby-rspec-mock/blob/master/README.md',
    'bug_tracker_uri' => 'https://github.com/mocktools/ruby-rspec-mock/issues'
  }

  spec.required_ruby_version = '>= 2.4.0'
  spec.files = `git ls-files -z`.split("\x0").select { |f| f.match(%r{^(bin|lib)/|.ruby-version|rspec-mock.gemspec|LICENSE}) }
  spec.require_paths = %w[lib]

  spec.add_runtime_dependency 'colorize', '>= 0.8.1'
  spec.add_runtime_dependency 'rspec-core', '~> 3.10'
  spec.add_runtime_dependency 'rspec-mocks', '~> 3.10'
  spec.add_runtime_dependency 'terminal-table', '~> 3.0'

  spec.add_development_dependency 'rspec', '~> 3.13'
end
