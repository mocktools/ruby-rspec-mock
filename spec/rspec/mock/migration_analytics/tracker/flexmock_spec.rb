# frozen_string_literal: true

RSpec.describe RSpec::Mock::MigrationAnalytics::Tracker::Flexmock do
  subject(:tracker) { described_class.new }

  describe '#initialize' do
    it 'initializes with empty collections and default values' do
      expect(tracker.flexmock_vars).to be_empty
      expect(tracker.flexmock_expectations).to be_empty
      expect(tracker.locations).to be_empty
      expect(tracker.block_level).to eq(0)
      expect(tracker.in_mock_block).to be false
    end
  end

  describe '#scan_line' do
    context 'with empty or comment lines' do
      it 'ignores empty lines' do
        tracker.scan_line('', 1)
        tracker.scan_line('   ', 2)
        expect(tracker.locations).to be_empty
      end

      it 'ignores comment lines' do
        tracker.scan_line('# flexmock(user)', 1)
        tracker.scan_line('  # mock.should_receive(:method)', 2)
        expect(tracker.locations).to be_empty
      end
    end

    context 'with direct FlexMock calls' do
      it 'detects FlexMock class calls' do
        tracker.scan_line('FlexMock.new', 1)
        expect(tracker.locations.first).to include(
          line_number: 1,
          content: 'FlexMock.new',
          type: 'flexmock related'
        )
      end
    end

    context 'with helper method calls' do
      it 'detects basic flexmock calls' do
        tracker.scan_line('flexmock(user)', 1)
        expect(tracker.locations.first).to include(
          line_number: 1,
          content: 'flexmock(user)',
          type: 'flexmock related'
        )
      end

      it 'detects new_instances blocks' do
        tracker.scan_line('flexmock(User).new_instances do |m|', 1)
        expect(tracker.locations.first).to include(
          line_number: 1,
          content: 'flexmock(User).new_instances do |m|',
          type: 'flexmock new_instances block'
        )
      end
    end

    context 'with variable assignments' do
      it 'tracks basic mock assignments' do
        tracker.scan_line('user_mock = flexmock(user)', 1)
        expect(tracker.flexmock_vars).to include('user_mock')
        expect(tracker.locations.first[:line_number]).to eq(1)
      end

      it 'tracks block parameter assignments' do
        tracker.scan_line('flexmock(User) do |mock|', 1)
        expect(tracker.flexmock_vars).to include('mock')
        expect(tracker.locations.first[:line_number]).to eq(1)
      end

      it 'tracks expectation assignments' do
        tracker.scan_line('expectation = mock.should_receive(:method)', 1)
        expect(tracker.flexmock_vars).to include('expectation')
      end
    end

    context 'with expectations' do
      it 'detects direct should_receive calls' do
        tracker.scan_line('flexmock(user).should_receive(:name)', 1)
        expect(tracker.locations.first).to include(
          type: 'flexmock expectation',
          line_number: 1
        )
      end
    end

    context 'with block tracking' do
      it 'tracks nested blocks' do
        tracker.scan_line('flexmock(user) do |mock|', 1)
        tracker.scan_line('  flexmock(other) do |other_mock|', 2)
        expect(tracker.block_level).to eq(2)
        expect(tracker.flexmock_vars).to include('mock', 'other_mock')

        tracker.scan_line('  end', 3)
        tracker.scan_line('end', 4)
        expect(tracker.block_level).to eq(0)
      end
    end

    context 'with variable references' do
      before do
        tracker.scan_line('user_mock = flexmock(user)', 1)
      end

      it 'detects method chains on tracked variables' do
        tracker.scan_line('user_mock.should_receive(:name)', 2)
        expect(tracker.locations.last[:line_number]).to eq(2)
      end

      it 'detects return value chains on tracked variables' do
        tracker.scan_line('user_mock.should_receive(:name).and_return("John")', 2)
        expect(tracker.locations.last[:line_number]).to eq(2)
      end

      it 'detects multiple expectations on tracked variables' do
        tracker.scan_line('user_mock.should_receive(:name).with("John").once', 2)
        tracker.scan_line('user_mock.should_receive(:email).and_return("john@example.com")', 3)
        expect(tracker.locations.map { |loc| loc[:line_number] }).to eq([1, 2, 3])
      end
    end

    context 'with RSpec blocks' do
      it 'detects flexmock in single-line blocks' do
        tracker.scan_line('it { flexmock(user) }', 1)
        expect(tracker.locations.first[:line_number]).to eq(1)
      end

      it 'detects flexmock in do-end blocks' do
        tracker.scan_line('it do', 1)
        tracker.scan_line('  flexmock(user)', 2)
        tracker.scan_line('end', 3)
        expect(tracker.locations.first[:line_number]).to eq(2)
      end

      it 'detects flexmock in before blocks' do
        tracker.scan_line('before { flexmock(user) }', 1)
        expect(tracker.locations.first[:line_number]).to eq(1)
      end

      it 'detects flexmock in let blocks' do
        tracker.scan_line('let(:mock) { flexmock(user) }', 1)
        expect(tracker.locations.first[:line_number]).to eq(1)
      end
    end
  end
end
