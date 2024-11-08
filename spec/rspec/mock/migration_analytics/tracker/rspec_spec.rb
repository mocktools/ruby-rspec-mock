# frozen_string_literal: true

RSpec.describe RSpec::Mock::MigrationAnalytics::Tracker::Rspec do
  subject(:tracker) { described_class.new }

  describe '#scan_line' do
    context 'when line is empty or comment' do
      it 'ignores empty lines' do
        tracker.scan_line('', 1)
        tracker.scan_line('    ', 2)

        expect(tracker.locations).to be_empty
      end

      it 'ignores comment lines' do
        tracker.scan_line('# this is a comment', 1)

        expect(tracker.locations).to be_empty
      end
    end

    context 'when scanning mock blocks' do
      it 'tracks single-line rspec_mock blocks' do
        tracker.scan_line('rspec_mock { expect(foo).to receive(:bar) }', 1)

        expect(tracker.locations).to contain_exactly(
          hash_including(
            line_number: 1,
            content: 'rspec_mock { expect(foo).to receive(:bar) }',
            type: 'expect mock'
          )
        )
      end

      it 'tracks multi-line rspec_mock blocks' do
        tracker.scan_line('rspec_mock do', 1)
        tracker.scan_line('  expect(foo).to receive(:bar)', 2)
        tracker.scan_line('  allow(baz).to receive(:qux)', 3)
        tracker.scan_line('end', 4)

        expect(tracker.locations).to contain_exactly(
          hash_including(
            line_number: 2,
            content: 'expect(foo).to receive(:bar)',
            type: 'expect mock'
          ),
          hash_including(
            line_number: 3,
            content: 'allow(baz).to receive(:qux)',
            type: 'allow mock'
          )
        )
      end
    end

    context 'when scanning different mock types' do
      before { tracker.scan_line('rspec_mock do', 1) }
      after { tracker.scan_line('end', 999) }

      it 'identifies spy verifications' do
        tracker.scan_line('expect(foo).to have_received(:bar)', 2)

        expect(tracker.locations.last).to include(
          line_number: 2,
          type: 'spy verification'
        )
      end

      it 'identifies expect mocks' do
        tracker.scan_line('expect(foo).to receive(:bar)', 2)

        expect(tracker.locations.last).to include(
          line_number: 2,
          type: 'expect mock'
        )
      end

      it 'identifies allow mocks' do
        tracker.scan_line('allow(foo).to receive(:bar)', 2)

        expect(tracker.locations.last).to include(
          line_number: 2,
          type: 'allow mock'
        )
      end

      it 'identifies mock chains' do
        tracker.scan_line('foo.to_receive(:bar).and_return(42)', 2)

        expect(tracker.locations.last).to include(
          line_number: 2,
          type: 'mock chain'
        )
      end
    end
  end
end
