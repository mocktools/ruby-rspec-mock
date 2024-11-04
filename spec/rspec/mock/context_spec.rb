# frozen_string_literal: true

RSpec.describe RSpec::Mock::Context do
  let(:example_group) { double('ExampleGroup') } # rubocop:disable RSpec/VerifiedDoubles
  let(:context) { described_class.new(example_group) }

  describe '#initialize' do
    it 'stores the example group' do
      expect(context.instance_variable_get(:@example_group)).to eq(example_group)
    end
  end

  describe '#method_missing' do
    context 'when example group responds to the method' do
      it 'delegates the method to example group' do
        expect(example_group).to receive(:respond_to?).with(:some_method).and_return(true)
        expect(example_group).to receive(:some_method).with('arg1', 'arg2').and_return('result')

        result = context.some_method('arg1', 'arg2')
        expect(result).to eq('result')
      end
    end

    context 'when example group does not respond to the method' do
      it 'raises NoMethodError' do
        expect(example_group).to receive(:respond_to?).with(:unknown_method)
        expect { context.unknown_method }.to raise_error(NoMethodError)
      end
    end
  end

  describe '#respond_to_missing?' do
    context 'when example group responds to the method' do
      it 'returns true' do
        expect(example_group).to receive(:respond_to?).with(:some_method, false).and_return(true)
        expect(context.respond_to?(:some_method)).to be(true)
      end
    end

    context 'when example group does not respond to the method' do
      it 'returns false' do
        expect(example_group).to receive(:respond_to?).with(:unknown_method, false).and_return(false)
        expect(context.respond_to?(:unknown_method)).to be(false)
      end
    end
  end
end
