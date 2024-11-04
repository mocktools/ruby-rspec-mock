# frozen_string_literal: true

RSpec.describe RSpec::Mock::Methods do
  let(:test_class) do
    Class.new do
      include RSpec::Mock::Methods
    end
  end

  let(:instance) { test_class.new }

  describe '#rspec_mock' do
    let(:mock_context) { instance_double(RSpec::Mock::Context) }

    before do
      allow(RSpec::Mock::Context).to receive(:new).and_return(mock_context)
      allow(mock_context).to receive(:instance_eval)
    end

    context 'when block is given' do
      it 'executes within temporary scope, creates context and evaluates the block' do
        expect(RSpec::Mocks).to receive(:with_temporary_scope).and_yield
        expect(RSpec::Mock::Context).to receive(:new).with(instance).and_return(mock_context)
        expect(mock_context).to receive(:instance_eval)
        instance.rspec_mock { nil }
      end
    end

    context 'when no block is given' do
      it 'does not create context or temporary scope' do
        expect(RSpec::Mock::Context).not_to receive(:new)
        expect(RSpec::Mocks).not_to receive(:with_temporary_scope)
        expect(instance.rspec_mock).to be_nil
      end
    end
  end
end
