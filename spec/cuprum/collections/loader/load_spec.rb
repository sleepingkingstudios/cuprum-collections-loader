# frozen_string_literal: true

require 'cuprum/collections/basic/collection'
require 'stannum/constraints/anything'

require 'cuprum/collections/loader/load'

RSpec.describe Cuprum::Collections::Loader::Load do
  subject(:command) { described_class.new(**constructor_options) }

  let(:data_path)           { 'path/to/data' }
  let(:constructor_options) { { data_path: data_path } }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:data_path)
    end
  end

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe '#call' do
    shared_examples 'should notify the observers' do
      context 'when the command has an observer' do
        let(:observer) { Spec::Observer.new }

        example_class 'Spec::Observer' do |klass|
          klass.define_method(:notifications) do
            @notifications ||= []
          end

          klass.define_method(:update) do |action, options|
            notifications << [action, options]
          end
        end

        before(:example) do
          command.add_observer(observer)
        end

        it 'should notify the observer' do
          call_command

          expect(observer.notifications)
            .to deep_match(expected_notifications)
        end
      end
    end

    let(:data) do
      [
        { 'name' => 'Publisher 1' },
        { 'name' => 'Publisher 2' },
        { 'name' => 'Publisher 3' }
      ]
    end
    let(:options)        { {} }
    let(:parsed_options) { { 'middleware' => [] } }
    let(:read_result)    { Cuprum::Result.new(value: [data, options]) }
    let(:parse_result)   { Cuprum::Result.new(value: parsed_options) }
    let(:upsert_results) do
      data.map do |attributes|
        Cuprum::Result.new(value: [:create, attributes])
      end
    end
    let(:read_double) do
      instance_double(Cuprum::Collections::Loader::Read, call: read_result)
    end
    let(:parse_double) do
      instance_double(
        Cuprum::Collections::Loader::Options::Parse,
        call: parse_result
      )
    end
    let(:upsert_double) do
      instance_double(Cuprum::Collections::Loader::Upsert, call: nil)
    end
    let(:expected_value) do
      upsert_results.map(&:value)
    end
    let(:collection) do
      Cuprum::Collections::Basic::Collection.new(
        collection_name:  'publishers',
        data:             [],
        default_contract: Stannum::Constraints::Anything
      )
    end
    let(:relative_path) { collection.collection_name }
    let(:expected_notifications) do
      [
        [
          :start,
          {
            collection_name: collection.collection_name,
            data:            data,
            data_path:       data_path,
            options:         options,
            relative_path:   relative_path
          }
        ],
        *upsert_results.each.with_index.map do |result, index|
          [
            result.status,
            {
              attributes:      data[index],
              collection_name: collection.collection_name,
              options:         parsed_options,
              result:          result
            }
          ]
        end,
        [
          :finish,
          {
            collection_name: collection.collection_name,
            results:         Cuprum::ResultList.new(*upsert_results)
          }
        ]
      ]
    end

    before(:example) do
      allow(Cuprum::Collections::Loader::Read)
        .to receive(:new)
        .and_return(read_double)

      allow(Cuprum::Collections::Loader::Options::Parse)
        .to receive(:new)
        .and_return(parse_double)

      allow(Cuprum::Collections::Loader::Upsert)
        .to receive(:new)
        .and_return(upsert_double)

      allow(upsert_double).to receive(:call).and_return(*upsert_results)
    end

    def call_command
      command.call(collection: collection)
    end

    it 'should define the method' do
      expect(command)
        .to be_callable
        .with(0).arguments
        .and_keywords(:collection, :relative_path)
    end

    it 'should return a passing result' do
      expect(command.call(collection: collection))
        .to be_a_passing_result
        .with_value(expected_value)
    end

    it 'should read the data', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      command.call(collection: collection)

      expect(Cuprum::Collections::Loader::Read)
        .to have_received(:new)
        .with(data_path: data_path)

      expect(read_double)
        .to have_received(:call)
        .with(relative_path: collection.collection_name)
    end

    it 'should parse the options' do
      command.call(collection: collection)

      expect(parse_double).to have_received(:call).with(options: options)
    end

    it 'should upsert the entities', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      command.call(collection: collection)

      expect(Cuprum::Collections::Loader::Upsert)
        .to have_received(:new)
        .with(attribute_names: 'id', collection: collection)

      data.each do |attributes|
        expect(upsert_double)
          .to have_received(:call)
          .with(attributes: attributes)
      end
    end

    include_examples 'should notify the observers'

    describe 'with relative_path: value' do
      let(:relative_path) { 'metadata/publishers' }

      def call_command
        command.call(collection: collection, relative_path: relative_path)
      end

      it 'should read the data', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        command.call(collection: collection, relative_path: relative_path)

        expect(Cuprum::Collections::Loader::Read)
          .to have_received(:new)
          .with(data_path: data_path)

        expect(read_double)
          .to have_received(:call)
          .with(relative_path: relative_path)
      end

      include_examples 'should notify the observers'
    end

    context 'when the read command returns a failing result' do
      let(:error)       { Cuprum::Error.new(message: 'Something went wrong.') }
      let(:read_result) { Cuprum::Result.new(error: error) }
      let(:expected_notifications) do
        [
          [
            :error,
            {
              collection_name: collection.collection_name,
              error:           read_result.error,
              relative_path:   relative_path
            }
          ]
        ]
      end

      it 'should return a failing result' do
        expect(command.call(collection: collection))
          .to be_a_failing_result
          .with_error(error)
      end

      include_examples 'should notify the observers'
    end

    context 'when the parse options command returns a failing result' do
      let(:error)        { Cuprum::Error.new(message: 'Something went wrong.') }
      let(:parse_result) { Cuprum::Result.new(error: error) }
      let(:expected_notifications) do
        [
          [
            :error,
            {
              collection_name: collection.collection_name,
              error:           parse_result.error,
              relative_path:   relative_path
            }
          ]
        ]
      end

      it 'should return a failing result' do
        expect(command.call(collection: collection))
          .to be_a_failing_result
          .with_error(error)
      end

      include_examples 'should notify the observers'
    end

    context 'when the upsert command returns a failing result' do
      let(:upsert_results) do
        Array.new(data.size) do
          Cuprum::Result.new(
            error: Cuprum::Error.new(message: 'Something went wrong.')
          )
        end
      end
      let(:expected_error) do
        Cuprum::Errors::MultipleErrors.new(
          errors: upsert_results.map(&:error)
        )
      end

      it 'should return a failing result' do
        expect(command.call(collection: collection))
          .to be_a_failing_result
          .with_value(expected_value)
          .and_error(expected_error)
      end

      include_examples 'should notify the observers'
    end

    context 'when the options includes a find_by attribute' do
      let(:parsed_options) { { 'find_by' => 'slug' } }

      it 'should upsert the entities', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        command.call(collection: collection)

        expect(Cuprum::Collections::Loader::Upsert)
          .to have_received(:new)
          .with(attribute_names: 'slug', collection: collection)

        data.each do |attributes|
          expect(upsert_double)
            .to have_received(:call)
            .with(attributes: attributes)
        end
      end

      include_examples 'should notify the observers'
    end

    context 'when the options include middleware' do
      let(:middleware) do
        [
          Spec::AddWebsite.new,
          Spec::GenerateSlug.new('name')
        ]
      end
      let(:parsed_options) { { 'middleware' => middleware } }
      let(:expected_data) do
        [
          { 'name' => 'Publisher 1', 'slug' => 'publisher-1' },
          { 'name' => 'Publisher 2', 'slug' => 'publisher-2' },
          { 'name' => 'Publisher 3', 'slug' => 'publisher-3' }
        ]
      end
      let(:upsert_results) do
        expected_data.map do |attributes|
          Cuprum::Result.new(
            value: [Spec::ComparablePublisher.new(attributes), :created]
          )
        end
      end

      example_class 'Spec::ComparablePublisher',
        Struct.new(:name, :slug, :website, keyword_init: true)

      example_class 'Spec::AddWebsite',
        Cuprum::Collections::Loader::Middleware::EntityMiddleware \
      do |klass|
        klass.define_method(:process) do |next_command, attributes:|
          entity, action =
            step { super(next_command, attributes: attributes) }

          if entity.website.nil? || entity.website.empty?
            entity.website = 'www.example.com'
          end

          [entity, action]
        end
      end

      example_class 'Spec::GenerateSlug',
        Cuprum::Collections::Loader::Middleware::AttributeMiddleware \
      do |klass|
        klass.define_method(:process) do |next_command, attributes:|
          attributes['slug'] ||=
            attributes[attribute_name]&.downcase&.tr(' ', '-')

          super(next_command, attributes: attributes)
        end
      end

      it 'should return a passing result' do
        expect(command.call(collection: collection))
          .to be_a_passing_result
          .with_value(expected_value)
      end

      it 'should upsert the entities', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        command.call(collection: collection)

        expect(Cuprum::Collections::Loader::Upsert)
          .to have_received(:new)
          .with(attribute_names: 'id', collection: collection)

        data.each do |attributes|
          expect(upsert_double)
            .to have_received(:call)
            .with(attributes: attributes)
        end
      end

      include_examples 'should notify the observers'
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  describe '#data_path' do
    include_examples 'should define reader', :data_path, -> { data_path }
  end
end
