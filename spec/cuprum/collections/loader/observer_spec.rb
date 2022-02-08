# frozen_string_literal: true

require 'cuprum/collections/loader/observer'

RSpec.describe Cuprum::Collections::Loader::Observer do
  subject(:observer) { described_class.new }

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  describe '#update' do
    let(:collection_name) { 'books' }
    let(:data_path)       { '/path/to/data' }
    let(:relative_path)   { '/path/to/books' }
    let(:error)           { Cuprum::Error.new(message: 'something went wrong') }
    let(:attributes)      { data.first }
    let(:options)         { { 'middleware' => [] } }
    let(:details)         { {} }
    let(:data) do
      [
        {
          'id'    => 0,
          'title' => 'Gideon the Ninth'
        },
        {
          'id'    => 0,
          'title' => 'Harrow the Ninth'
        },
        {
          'id'    => 2,
          'title' => 'Nona the Ninth'
        }
      ]
    end

    it { expect(observer).to respond_to(:update).with(2).arguments }

    describe 'with an invalid action' do
      let(:error_message) do
        /undefined method `invalid'/
      end

      it 'should raise an exception' do
        expect { observer.update(:invalid, {}) }
          .to raise_error NoMethodError, error_message
      end
    end

    describe 'with :error' do
      let(:details) do
        {
          collection_name: collection_name,
          error:           error,
          relative_path:   collection_name
        }
      end
      let(:expected_output) do
        <<~OUTPUT
          [Error] An error occurred when loading books: #{error.message}
        OUTPUT
      end

      it 'should write to STDOUT' do
        expect { observer.update(:error, details) }
          .to output(expected_output)
          .to_stdout
      end

      describe 'with relative_path: value' do
        let(:details) do
          super().merge(relative_path: relative_path)
        end
        let(:expected_output) do
          <<~OUTPUT
            [Error] An error occurred when loading books (#{relative_path}): #{error.message}
          OUTPUT
        end

        it 'should write to STDOUT' do
          expect { observer.update(:error, details) }
            .to output(expected_output)
            .to_stdout
        end
      end
    end

    describe 'with :failure' do
      let(:result) do
        Cuprum::Result.new(
          status: :failure,
          error:  error,
          value:  ['calculate', nil]
        )
      end
      let(:details) do
        {
          attributes:      attributes,
          collection_name: collection_name,
          options:         options,
          result:          result
        }
      end
      let(:expected_output) do
        "- Unable to calculate book with id 0: #{error.message}\n"
      end

      it 'should write to STDOUT' do
        expect { observer.update(:failure, details) }
          .to output(expected_output)
          .to_stdout
      end

      describe 'with find_by: a value' do
        let(:options) { super().merge('find_by' => 'title') }
        let(:expected_output) do
          '- Unable to calculate book with title "Gideon the Ninth":' \
            " #{error.message}\n"
        end

        it 'should write to STDOUT' do
          expect { observer.update(:failure, details) }
            .to output(expected_output)
            .to_stdout
        end
      end

      describe 'with find_by: an Array' do
        let(:options) { super().merge('find_by' => %w[id title]) }
        let(:expected_output) do
          '- Unable to calculate book with id 0, title "Gideon the Ninth":' \
            " #{error.message}\n"
        end

        it 'should write to STDOUT' do
          expect { observer.update(:failure, details) }
            .to output(expected_output)
            .to_stdout
        end
      end
    end

    describe 'with :start' do
      let(:details) do
        {
          collection_name: collection_name,
          data:            data,
          data_path:       data_path,
          relative_path:   relative_path
        }
      end
      let(:expected_output) do
        "Loading 3 books from /path/to/data/path/to/books\n"
      end

      it 'should write to STDOUT' do
        expect { observer.update(:start, details) }
          .to output(expected_output)
          .to_stdout
      end

      context 'when there is one item in data' do
        let(:data) { super()[0..0] }
        let(:expected_output) do
          "Loading 1 book from /path/to/data/path/to/books\n"
        end

        it 'should write to STDOUT' do
          expect { observer.update(:start, details) }
            .to output(expected_output)
            .to_stdout
        end
      end
    end

    # rubocop:disable RSpec/MultipleMemoizedHelpers
    describe 'with :success' do
      let(:value)  { { 'id' => '0', 'title' => 'GIDEON THE NINTH' } }
      let(:result) { Cuprum::Result.new(value: ['calculate', value]) }
      let(:details) do
        {
          attributes:      attributes,
          collection_name: collection_name,
          options:         options,
          result:          result
        }
      end
      let(:expected_output) do
        "- Successfully calculated book with id \"0\"\n"
      end

      it 'should write to STDOUT' do
        expect { observer.update(:success, details) }
          .to output(expected_output)
          .to_stdout
      end

      describe 'with result: a value without the attribute' do
        let(:value) { {} }
        let(:expected_output) do
          "- Successfully calculated book with id 0\n"
        end

        it 'should write to STDOUT' do
          expect { observer.update(:success, details) }
            .to output(expected_output)
            .to_stdout
        end
      end

      describe 'with find_by: a value' do
        let(:options) { super().merge('find_by' => 'title') }
        let(:expected_output) do
          "- Successfully calculated book with title \"GIDEON THE NINTH\"\n"
        end

        it 'should write to STDOUT' do
          expect { observer.update(:success, details) }
            .to output(expected_output)
            .to_stdout
        end

        describe 'with result: a value without the attribute' do
          let(:value) { {} }
          let(:expected_output) do
            "- Successfully calculated book with title \"Gideon the Ninth\"\n"
          end

          it 'should write to STDOUT' do
            expect { observer.update(:success, details) }
              .to output(expected_output)
              .to_stdout
          end
        end
      end

      describe 'with find_by: an Array' do
        let(:options) { super().merge('find_by' => %w[id title]) }
        let(:expected_output) do
          '- Successfully calculated book with id "0", title' \
            " \"GIDEON THE NINTH\"\n"
        end

        it 'should write to STDOUT' do
          expect { observer.update(:success, details) }
            .to output(expected_output)
            .to_stdout
        end

        describe 'with result: a value without the attribute' do
          let(:value) { {} }
          let(:expected_output) do
            '- Successfully calculated book with id 0, title' \
              " \"Gideon the Ninth\"\n"
          end

          it 'should write to STDOUT' do
            expect { observer.update(:success, details) }
              .to output(expected_output)
              .to_stdout
          end
        end
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end
end
