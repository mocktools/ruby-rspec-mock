# frozen_string_literal: true

RSpec.describe RSpec::Mock::MigrationAnalytics::Cli do
  let(:sample_file_path) { 'spec/models/user_spec.rb' }
  let(:sample_dir_path) { 'spec/models' }

  shared_context 'with stubbed ENV' do
    before do
      allow(ENV).to receive(:[]).and_return(nil)
      allow(ENV).to receive(:[]).with('COLUMNS').and_return('80')
    end
  end

  describe '.call' do
    context 'when no arguments are provided' do
      before { stub_const('ARGV', []) }

      it 'prints usage and exits with status 1' do
        expect(described_class).to receive(:print_usage)
        expect { described_class.call }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context 'when path is provided' do
      before { stub_const('ARGV', [sample_file_path]) }

      it 'verifies the provided path' do
        expect(described_class).to receive(:verify_path).with(sample_file_path)
        described_class.call
      end

      context 'when an error occurs' do
        let(:error_message) { 'Something went wrong' }

        before do
          allow(described_class).to receive(:verify_path).and_raise(StandardError.new(error_message))
          allow(ENV).to receive(:[]).and_return(nil)
          allow(ENV).to receive(:[]).with('COLUMNS').and_return('80')
        end

        it 'prints the error message in red' do
          expect { described_class.call }
            .to output(/❌ Error: #{error_message}/).to_stdout
        end

        context 'when DEBUG env is set' do
          before do
            allow(ENV).to receive(:[]).with('DEBUG').and_return('true')
          end

          it 'prints the backtrace' do
            expect { described_class.call }
              .to output(%r{#{error_message}.*gems/rspec}m).to_stdout
          end
        end
      end
    end
  end

  describe '.verify_path' do
    context 'when path is a directory' do
      before { allow(File).to receive(:directory?).with(sample_dir_path).and_return(true) }

      it 'calls verify_directory' do
        expect(described_class).to receive(:verify_directory).with(sample_dir_path)
        described_class.verify_path(sample_dir_path)
      end
    end

    context 'when path is a file' do
      before { allow(File).to receive(:directory?).with(sample_file_path).and_return(false) }

      it 'calls verify_file' do
        expect(described_class).to receive(:verify_file).with(sample_file_path)
        described_class.verify_path(sample_file_path)
      end
    end
  end

  describe '.verify_file' do
    include_context 'with stubbed ENV'

    context 'when file does not exist' do
      before { allow(File).to receive(:exist?).with(sample_file_path).and_return(false) }

      it 'prints error message' do
        expect { described_class.send(:verify_file, sample_file_path) }
          .to output(/File not found: #{sample_file_path}/).to_stdout
      end
    end

    context 'when file is not a spec file' do
      let(:non_spec_file) { 'app/models/user.rb' }

      before { allow(File).to receive(:exist?).with(non_spec_file).and_return(true) }

      it 'prints warning message' do
        expect { described_class.send(:verify_file, non_spec_file) }
          .to output(/Not a Ruby spec file: #{non_spec_file}/).to_stdout
      end
    end

    context 'when file is valid spec file' do
      let(:analysis_result) do
        {
          file_path: sample_file_path,
          has_mocks: true,
          flexmock_count: 2,
          rspec_mock_count: 3,
          flexmock_locations: [{ line_number: 1, type: 'migration mock block', content: 'mock code' }],
          rspec_mock_locations: [{ line_number: 2, type: 'expect mock', content: 'expect code' }]
        }
      end

      before do
        allow(File).to receive(:exist?).with(sample_file_path).and_return(true)
        allow(RSpec::Mock::MigrationAnalytics::FileAnalyzer).to receive(:call)
          .with(sample_file_path).and_return(analysis_result)
      end

      it 'prints analysis results' do
        expect { described_class.send(:verify_file, sample_file_path) }
          .to output(/=== Mock Usage Analysis:.*Mock Usage/m)
          .to_stdout
      end
    end

    context 'when file has no mocks' do
      let(:analysis_result) do
        {
          file_path: sample_file_path,
          has_mocks: false,
          flexmock_count: 0,
          rspec_mock_count: 0,
          flexmock_locations: [],
          rspec_mock_locations: []
        }
      end

      before do
        allow(File).to receive(:exist?).with(sample_file_path).and_return(true)
        allow(RSpec::Mock::MigrationAnalytics::FileAnalyzer).to receive(:call)
          .with(sample_file_path).and_return(analysis_result)
      end

      it 'prints no mocking usage found message' do
        expect { described_class.send(:verify_file, sample_file_path) }
          .to output(/✅ No mocking usage found/).to_stdout
      end
    end
  end

  describe '.verify_directory' do
    include_context 'with stubbed ENV'

    let(:spec_files) { ['spec/model1_spec.rb', 'spec/model2_spec.rb'] }
    let(:analysis_results) do
      [
        {
          file_path: spec_files[0],
          has_mocks: true,
          flexmock_count: 1,
          rspec_mock_count: 2,
          has_mixed_usage: true,
          flexmock_locations: [],
          rspec_mock_locations: []
        },
        {
          file_path: spec_files[1],
          has_mocks: true,
          flexmock_count: 2,
          rspec_mock_count: 1,
          has_mixed_usage: false,
          flexmock_locations: [],
          rspec_mock_locations: []
        }
      ]
    end

    before do
      allow(Dir).to receive(:glob).with("#{sample_dir_path}/**/*_spec.rb").and_return(spec_files)
      allow(RSpec::Mock::MigrationAnalytics::FileAnalyzer).to receive(:call)
        .and_return(*analysis_results)
    end

    it 'analyzes all spec files and prints summary' do
      expect { described_class.send(:verify_directory, sample_dir_path) }
        .to output(/=== Migration Status Report ===.*Files Requiring Migration/m).to_stdout
    end
  end

  describe 'helper methods' do
    describe '.create_location_row' do
      it 'formats location data with correct colors' do
        location = { line_number: 1, type: 'expect mock', content: 'test content' }
        row = described_class.send(:create_location_row, location)
        expect(row).to be_an(Array)
        expect(row.size).to eq(3)
      end
    end

    describe '.determine_color' do
      {
        'migration mock block' => :cyan,
        'expect mock' => :blue,
        'allow mock' => :blue,
        'verifying double' => :green,
        'unknown' => :light_white
      }.each do |type, expected_color|
        it "returns #{expected_color} for #{type}" do
          expect(described_class.send(:determine_color, type)).to eq(expected_color)
        end
      end
    end
  end

  describe '.print_usage' do
    include_context 'with stubbed ENV'

    it 'prints usage instructions with examples' do
      expected_lines = [
        'Usage: ruby cli.rb <path_to_spec_file_or_directory>',
        '',
        'Examples:',
        '  ruby cli.rb spec/models/user_spec.rb',
        '  ruby cli.rb spec/models/',
        '  ruby cli.rb spec/'
      ]

      expect { described_class.send(:print_usage) }
        .to output(/#{expected_lines.join('.*')}/m)
        .to_stdout
    end
  end
end
