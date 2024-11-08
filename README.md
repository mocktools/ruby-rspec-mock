# Seamless migration from third-party mocks to RSpec built-in mocking framework

[![Maintainability](https://api.codeclimate.com/v1/badges/8a7a9ca7f590838bf02f/maintainability)](https://codeclimate.com/github/mocktools/ruby-rspec-mock/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/8a7a9ca7f590838bf02f/test_coverage)](https://codeclimate.com/github/mocktools/ruby-rspec-mock/test_coverage)
[![CircleCI](https://circleci.com/gh/mocktools/ruby-rspec-mock/tree/master.svg?style=svg)](https://circleci.com/gh/mocktools/ruby-rspec-mock/tree/master)
[![Gem Version](https://badge.fury.io/rb/rspec-mock.svg)](https://badge.fury.io/rb/rspec-mock)
[![Downloads](https://img.shields.io/gem/dt/rspec-mock.svg?colorA=004d99&colorB=0073e6)](https://rubygems.org/gems/rspec-mock)
[![GitHub](https://img.shields.io/github/license/mocktools/ruby-rspec-mock)](LICENSE.txt)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v1.4%20adopted-ff69b4.svg)](CODE_OF_CONDUCT.md)

`rspec-mock` is a lightweight gem designed to ease the transition to RSpec's built-in mocking framework by allowing developers to use RSpec's mocks as secondary, alongside a primary, alternative mocking library. This setup enables new code to leverage RSpec’s built-in mocks directly, while still supporting legacy code that relies on an external mocking library.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - [Configuration](#configuration)
  - [Integration](#integration)
  - [Migration Analytics](#migration-analytics)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)
- [Credits](#credits)
- [Versioning](#versioning)
- [Changelog](CHANGELOG.md)

## Features

- Dual Mocking Compatibility: Use RSpec’s built-in mock framework as a secondary, with your primary mock of choice (e.g., Mocha, FlexMock).
- Seamless Transition: Adopt `RSpec::Mocks` in new tests gradually, without disrupting existing tests dependent on an alternative mocking library.
- Simplified Migration Path: Makes it easy to phase out external mocking libraries over time, moving towards a more unified, RSpec-native mocking approach.

## Requirements

Ruby MRI 2.5.0+

## Installation

Add this line to your application's `Gemfile`:

```ruby
group :test do
  gem 'rspec-mock', require: false
end
```

And then execute:

```bash
bundle
```

Or install it yourself as:

```bash
gem install rspec-mock
```

## Usage

### Configuration

```ruby
# spec/support/config/rspec_mock.rb

require 'rspec/mock'

RSpec.configure do |config|
  config.rspec_mock do |mock|
    mock.verify_partial_doubles = true
  end

  config.include RSpec::Mock::Methods
end
```

### Integration

```ruby
# spec/spec_helper.rb

RSpec.configure do |config|
  config.mock_framework = :flexmock
end

# spec/sandbox_spec.rb

RSpec.describe Sandbox do
  describe '.call' do
    subject(:service) { described_class.call(*args, **kwargs) }

    let(:args) { [1, 2, 3] }
    let(:kwargs) { { a: 1, b: 2 } }
    let(:expected_result) { { args:, kwargs: } }

    context 'when multiple mocks' do
      before do
        flexmock(described_class)
          .should_receive(:new)
          .with(*args, **kwargs)
          .pass_thru

        rspec_mock do
          allow(described_class)
            .to receive(:call)
            .with(*args, **kwargs)
            .and_call_original
        end
      end

      it { is_expected.to eq(expected_result) }
    end

    context 'when single mock' do
      it do
        rspec_mock do
          expect(described_class)
            .to receive(:call)
            .with(*args, **kwargs)
            .and_call_original
          expect(service).to eq(expected_result)
        end
      end
    end
  end
end
```

### Migration Analytics

You can create a Rake task to analyze Flexmock usage and track migration progress to RSpec mocks. Or use the CLI directly.

Example of the Rake task:

```ruby
namespace :rspec_mock do
  namespace :migration_analytics do
    desc 'Analyze Flexmock usage and track migration progress to RSpec mocks'
    task :flexmock, %i[path] do |_, args|
      require 'rspec/mock/migration_analytics/cli'

      path = args[:path] || 'spec'
      puts("\n🔍 Analyzing Flexmock usage in: #{path}")
      RSpec::Mock::MigrationAnalytics::Cli.verify_path(path)
    end
  end
end
```

```bash
# Analyze entire spec directory (default)
rake rspec_mock:migration_analytics:flexmock

# Analyze specific directory
rake rspec_mock:migration_analytics:flexmock spec/services

# Analyze specific file
rake rspec_mock:migration_analytics:flexmock spec/services/sandbox_service_spec.rb
```

Example of the CLI usage:

```bash
ruby cli.rb spec
ruby cli.rb spec/services
ruby cli.rb spec/services/sandbox_service_spec.rb
```

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/mocktools/ruby-rspec-mock>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct. Please check the [open tickets](https://github.com/mocktools/ruby-rspec-mock/issues). Be sure to follow Contributor Code of Conduct below and our [Contributing Guidelines](CONTRIBUTING.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RSpec::Mock project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

## Credits

- [The Contributors](https://github.com/mocktools/ruby-rspec-mock/graphs/contributors) for code and awesome suggestions
- [The Stargazers](https://github.com/mocktools/ruby-rspec-mock/stargazers) for showing their support

## Versioning

RSpec::Mock uses [Semantic Versioning 2.0.0](https://semver.org)
