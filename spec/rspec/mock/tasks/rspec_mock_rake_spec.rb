# frozen_string_literal: true

RSpec.describe 'RSpec::Mock rake task' do # rubocop:disable RSpec/DescribeClass
  include Rake::DSL

  let(:printer_class) { RSpec::Mock::MigrationAnalytics::Printer }

  before do
    Rake::Task.clear
    RSpec::Mock::Task.load
  end

  describe 'rspec_mock:migration_analytics:flexmock' do
    let(:task) { Rake::Task['rspec_mock:migration_analytics:flexmock'] }

    it { expect(task).to be_instance_of(Rake::Task) }

    context 'when executing the task' do
      context 'with default path' do
        before { stub_const('ARGV', ['rspec_mock:migration_analytics:flexmock']) }

        it 'calls Printer with default path' do
          expect(printer_class).to receive(:call).with('spec')
          task.execute
        end
      end

      context 'with custom path argument' do
        before { stub_const('ARGV', ['rspec_mock:migration_analytics:flexmock', 'custom/path']) }

        it 'calls Printer with custom path' do
          expect(printer_class).to receive(:call).with('custom/path')
          task.execute
        end
      end
    end
  end
end
