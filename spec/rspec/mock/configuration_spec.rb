# frozen_string_literal: true

RSpec.describe RSpec::Mock::Configuration do
  let(:test_class) do
    Class.new do
      include RSpec::Mock::Configuration
    end
  end

  let(:instance) { test_class.new }
  let(:mock_config) { instance_double('RSpec::Mocks::Configuration') }

  before { allow(RSpec::Mocks).to receive(:configuration).and_return(mock_config) }

  describe '#rspec_mock' do
    context 'when block is given' do
      it 'yields the configuration object' do
        expect(mock_config).to receive(:tap).and_yield(mock_config)
        expect { |block| instance.rspec_mock(&block) }.to yield_with_args(mock_config)
      end
    end

    context 'when no block is given' do
      it 'returns the configuration object' do
        expect(mock_config).to receive(:tap)
        expect(instance.rspec_mock).to be_nil
      end
    end
  end
end
