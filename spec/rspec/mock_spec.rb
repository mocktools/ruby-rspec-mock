# frozen_string_literal: true

RSpec.describe 'integration' do # rubocop:disable RSpec/DescribeClass
  subject(:service) { test_class.call(*args, **kwargs) }

  let(:test_class) do
    Class.new do
      def self.call(*args, **kwargs)
        { args: args, kwargs: kwargs }
      end
    end
  end
  let(:args) { [1, 2, 3] }
  let(:kwargs) { { a: 1, b: 2 } }
  let(:expected_result) { { args: args, kwargs: kwargs } }

  context 'with before block' do
    before do
      rspec_mock do
        allow(test_class)
          .to receive(:call)
          .with(*args, **kwargs)
          .and_call_original
      end
    end

    it { is_expected.to eq(expected_result) }
  end

  context 'without before block' do
    it do
      rspec_mock do
        expect(test_class)
          .to receive(:call)
          .with(*args, **kwargs)
          .and_call_original

        expect(service).to eq(expected_result)
      end
    end
  end
end
