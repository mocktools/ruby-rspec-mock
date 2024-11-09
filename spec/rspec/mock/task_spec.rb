# frozen_string_literal: true

RSpec.describe RSpec::Mock::Task do
  it 'loads the rake task' do
    described_class.load
    expect(::Rake::Task.task_defined?('rspec_mock:migration_analytics:flexmock')).to be(true)
  end
end
