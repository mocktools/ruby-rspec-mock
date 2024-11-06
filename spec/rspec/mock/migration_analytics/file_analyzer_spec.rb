# frozen_string_literal: true

RSpec.describe RSpec::Mock::MigrationAnalytics::FileAnalyzer do
  describe '.call' do
    subject(:result) { create_result(described_class.call(temporary_spec_file.path)) }

    let(:temporary_spec_file) { create_file }

    after do
      temporary_spec_file.close
      temporary_spec_file.unlink
    end

    context 'when flexmock usage' do
      context 'with flexmock usage with do-end block' do
        before do
          temporary_spec_file.write(<<~RSPEC)
            RSpec.describe MyClass do
              let(:mock_in_let) { flexmock(MyClass) }
              let!(:mock_in_let!) { flexmock(MyClass) }

              def mock_in_method
                flexmock(MyClass)
              end

              it 'mocks something' do
                mock = flexmock(MyClass)
                mock.should_receive(:method).once
              end
            end
          RSPEC
          temporary_spec_file.rewind
        end

        it do
          expect(result.flexmock_count).to eq(5)
          expect(result.rspec_mock_count).to eq(0)
          expect(result.has_mocks).to be(true)
        end
      end

      context 'with flexmock usage with {} block' do
        before do
          temporary_spec_file.write(<<~RSPEC)
            RSpec.describe MyClass do
              it { flexmock(MyClass).should_receive(:method).once }
            end
          RSPEC
          temporary_spec_file.rewind
        end

        it do
          expect(result.flexmock_count).to eq(1)
          expect(result.rspec_mock_count).to eq(0)
          expect(result.has_mocks).to be(true)
        end
      end
    end

    context 'when rspec mock usage' do
      context 'with rspec mock usage in rspec_mock block with do-end block' do
        before do
          temporary_spec_file.write(<<~RSPEC)
            RSpec.describe MyClass do
              before do
                rspec_mock do
                  mock = instance_double(MyClass)
                  allow(MyClass).to receive(:method).and_return(mock)
                end
              end

              it 'mocks something' do
                rspec_mock do
                  expect(MyClass).to receive(:method)
                end
              end
            end
          RSPEC
          temporary_spec_file.rewind
        end

        it do
          expect(result.flexmock_count).to eq(0)
          expect(result.rspec_mock_count).to eq(3)
          expect(result.has_mocks).to be(true)
        end
      end

      context 'with rspec mock usage in rspec_mock block with {} block' do
        before do
          temporary_spec_file.write(<<~RSPEC)
            RSpec.describe MyClass do
              it { rspec_mock { expect(MyClass).to receive(:method) } }
            end
          RSPEC
          temporary_spec_file.rewind
        end

        it do
          expect(result.flexmock_count).to eq(0)
          expect(result.rspec_mock_count).to eq(1)
          expect(result.has_mocks).to be(true)
        end
      end
    end

    context 'when mixed usage' do
      context 'with flexmock and rspec mock usage with do-end block' do
        before do
          temporary_spec_file.write(<<~RSPEC)
            RSpec.describe MyClass do
              it 'uses both mock types' do
                mock = flexmock(MyClass)
                rspec_mock do
                  expect(OtherClass).to receive(:method)
                end
              end
            end
          RSPEC
          temporary_spec_file.rewind
        end

        it do
          expect(result.flexmock_count).to eq(1)
          expect(result.rspec_mock_count).to eq(1)
          expect(result.has_mixed_usage).to be(true)
        end
      end

      context 'with flexmock and rspec mock usage with {} block' do
        before do
          temporary_spec_file.write(<<~RSPEC)
            RSpec.describe MyClass do
              it { flexmock(MyClass).should_receive(:method).once; rspec_mock { expect(OtherClass).to receive(:method) } }
            end
          RSPEC
          temporary_spec_file.rewind
        end

        it do
          expect(result.flexmock_count).to eq(1)
          expect(result.rspec_mock_count).to eq(1)
          expect(result.has_mixed_usage).to be(true)
        end
      end
    end
  end
end
