# frozen_string_literal: true

require 'cuprum/collections/basic/repository'

require 'cuprum/collections/loader/middleware/find_association'

RSpec.describe Cuprum::Collections::Loader::Middleware::FindAssociation do
  subject(:middleware) do
    described_class.new(attribute_name, repository: repository, **options)
  end

  let(:attribute_name) { 'user' }
  let(:repository)     { Cuprum::Collections::Basic::Repository.new }
  let(:options)        { {} }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(1).argument
        .and_keywords(:find_by, :optional, :qualified_name, :repository)
        .and_any_keywords
    end
  end

  describe '#attribute_name' do
    include_examples 'should define reader',
      :attribute_name,
      -> { be == attribute_name }
  end

  describe '#call' do
    shared_context 'when the collection exists' do
      let(:collection) do
        Cuprum::Collections::Basic::Collection.new(
          collection_name: 'users',
          data:            [],
          qualified_name:  middleware.qualified_name
        )
      end

      before(:example) { repository.add(collection) }
    end

    shared_examples 'should require the collection exists' do
      context 'when the collection does not exist' do
        let(:expected_error) do
          Cuprum::Collections::Loader::Errors::CollectionError.new(
            qualified_name: middleware.qualified_name,
            repository:     repository
          )
        end

        it 'should return a failing result' do
          expect(middleware.call(next_command, attributes: attributes))
            .to be_a_failing_result
            .with_error(expected_error)
        end

        it 'should not call the next command' do
          allow(next_command).to receive(:call)

          middleware.call(next_command, attributes: attributes)

          expect(next_command).not_to have_received(:call)
        end
      end
    end

    let(:attributes) { { 'user' => 0 } }
    let(:find_by)    { 'id' }
    let(:next_command) do
      Cuprum::Command.new { |hsh| hsh.merge({ 'ok' => true }) }
    end

    it 'should define the method' do
      expect(middleware)
        .to be_callable
        .with(1).argument
        .and_keywords(:attributes)
    end

    include_examples 'should require the collection exists'

    context 'when the association does not exist' do
      include_context 'when the collection exists'

      let(:expected_error) do
        Cuprum::Collections::Errors::NotFound.new(
          attributes:      { find_by => attributes[attribute_name] },
          collection_name: collection.collection_name
        )
      end

      context 'when the attribute value is nil' do
        let(:attributes) { {} }

        it 'should return a failing result' do
          expect(middleware.call(next_command, attributes: attributes))
            .to be_a_failing_result
            .with_error(expected_error)
        end

        it 'should not call the next command' do
          allow(next_command).to receive(:call)

          middleware.call(next_command, attributes: attributes)

          expect(next_command).not_to have_received(:call)
        end
      end

      context 'when the attribute value is a value' do
        let(:attributes) { { 'user' => 0 } }

        it 'should return a failing result' do
          expect(middleware.call(next_command, attributes: attributes))
            .to be_a_failing_result
            .with_error(expected_error)
        end

        it 'should not call the next command' do
          allow(next_command).to receive(:call)

          middleware.call(next_command, attributes: attributes)

          expect(next_command).not_to have_received(:call)
        end
      end

      context 'when initialized with optional: true' do
        let(:options)    { super().merge(optional: true) }
        let(:attributes) { { 'user' => 0 } }
        let(:expected_value) do
          {
            attributes: attributes.merge(attribute_name => nil),
            'ok' => true
          }
        end

        it 'should return a passing result' do
          expect(middleware.call(next_command, attributes: attributes))
            .to be_a_passing_result
            .with_value(expected_value)
        end

        it 'should call the next command' do
          allow(next_command).to receive(:call)

          middleware.call(next_command, attributes: attributes)

          expect(next_command)
            .to have_received(:call)
            .with(attributes: attributes.merge(attribute_name => nil))
        end
      end
    end

    context 'when the association exists' do
      include_context 'when the collection exists'

      let(:association) { { 'id' => 0, 'name' => 'Alan Bradley' } }
      let(:attributes)  { { 'user' => 0, 'password' => '12345' } }
      let(:expected_value) do
        {
          attributes: attributes.merge(attribute_name => association),
          'ok' => true
        }
      end

      before(:example) do
        collection.insert_one.call(entity: association)
      end

      it 'should return a passing result' do
        expect(middleware.call(next_command, attributes: attributes))
          .to be_a_passing_result
          .with_value(expected_value)
      end

      it 'should call the next command' do
        allow(next_command).to receive(:call)

        middleware.call(next_command, attributes: attributes)

        expect(next_command)
          .to have_received(:call)
          .with(attributes: attributes.merge(attribute_name => association))
      end
    end

    context 'when initialized with find_by: a String' do
      let(:find_by) { 'name' }
      let(:options) { super().merge(find_by: find_by) }

      include_examples 'should require the collection exists'

      context 'when the association does not exist' do
        include_context 'when the collection exists'

        let(:expected_error) do
          Cuprum::Collections::Errors::NotFound.new(
            attributes:      { find_by => attributes[attribute_name] },
            collection_name: collection.collection_name
          )
        end

        context 'when the attribute value is nil' do
          let(:attributes) { {} }

          it 'should return a failing result' do
            expect(middleware.call(next_command, attributes: attributes))
              .to be_a_failing_result
              .with_error(expected_error)
          end

          it 'should not call the next command' do
            allow(next_command).to receive(:call)

            middleware.call(next_command, attributes: attributes)

            expect(next_command).not_to have_received(:call)
          end
        end

        context 'when the attribute value is a value' do
          let(:attributes) { { 'user' => 'Alan Bradley' } }

          it 'should return a failing result' do
            expect(middleware.call(next_command, attributes: attributes))
              .to be_a_failing_result
              .with_error(expected_error)
          end

          it 'should not call the next command' do
            allow(next_command).to receive(:call)

            middleware.call(next_command, attributes: attributes)

            expect(next_command).not_to have_received(:call)
          end
        end

        context 'when initialized with optional: true' do
          let(:options)    { super().merge(optional: true) }
          let(:attributes) { { 'user' => 'Alan Bradley' } }
          let(:expected_value) do
            {
              attributes: attributes.merge(attribute_name => nil),
              'ok' => true
            }
          end

          it 'should return a passing result' do
            expect(middleware.call(next_command, attributes: attributes))
              .to be_a_passing_result
              .with_value(expected_value)
          end

          it 'should call the next command' do
            allow(next_command).to receive(:call)

            middleware.call(next_command, attributes: attributes)

            expect(next_command)
              .to have_received(:call)
              .with(attributes: attributes.merge(attribute_name => nil))
          end
        end
      end

      context 'when the association exists' do
        include_context 'when the collection exists'

        let(:association) { { 'id' => 0, 'name' => 'Alan Bradley' } }
        let(:attributes) do
          { 'user' => 'Alan Bradley', 'password' => '12345' }
        end
        let(:expected_value) do
          {
            attributes: attributes.merge(attribute_name => association),
            'ok' => true
          }
        end

        before(:example) do
          collection.insert_one.call(entity: association)
        end

        it 'should return a passing result' do
          expect(middleware.call(next_command, attributes: attributes))
            .to be_a_passing_result
            .with_value(expected_value)
        end

        it 'should call the next command' do
          allow(next_command).to receive(:call)

          middleware.call(next_command, attributes: attributes)

          expect(next_command)
            .to have_received(:call)
            .with(attributes: attributes.merge(attribute_name => association))
        end
      end
    end
  end

  describe '#find_by' do
    include_examples 'should define reader', :find_by, 'id'

    context 'when initialized with find_by: value' do
      let(:find_by)  { 'name' }
      let(:options)  { super().merge(find_by: find_by) }

      it { expect(middleware.find_by).to be == find_by }
    end
  end

  describe '#optional?' do
    include_examples 'should define predicate', :optional?, false

    context 'when initialized with optional: false' do
      let(:options) { super().merge(optional: false) }
      let(:expected) { super().merge(optional: false) }

      it { expect(middleware.optional?).to be false }
    end

    context 'when initialized with optional: true' do
      let(:options) { super().merge(optional: true) }

      it { expect(middleware.optional?).to be true }
    end
  end

  describe '#options' do
    let(:expected) do
      options.merge(
        find_by:        'id',
        optional:       false,
        qualified_name: nil,
        repository:     repository
      )
    end

    include_examples 'should define reader', :options, -> { be == expected }

    context 'when initialized with find_by: value' do
      let(:find_by)  { 'name' }
      let(:options)  { super().merge(find_by: find_by) }
      let(:expected) { super().merge(find_by: find_by) }

      it { expect(middleware.options).to be == expected }
    end

    context 'when initialized with optional: false' do
      let(:options)  { super().merge(optional: false) }
      let(:expected) { super().merge(optional: false) }

      it { expect(middleware.options).to be == expected }
    end

    context 'when initialized with optional: true' do
      let(:options)  { super().merge(optional: true) }
      let(:expected) { super().merge(optional: true) }

      it { expect(middleware.options).to be == expected }
    end

    context 'when initialized with qualified_name: value' do
      let(:options)  { super().merge(qualified_name: 'title') }
      let(:expected) { super().merge(qualified_name: 'title') }

      it { expect(middleware.options).to be == expected }
    end

    context 'when initialized with options' do
      let(:options)  { super().merge(key: 'value') }
      let(:expected) { super().merge(key: 'value') }

      it { expect(middleware.options).to be == expected }
    end
  end

  describe '#qualified_name' do
    let(:expected) { tools.string_tools.pluralize(attribute_name) }

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end

    include_examples 'should define reader', :qualified_name, -> { expected }

    context 'when initialized with qualified_name: value' do
      let(:qualified_name) { 'path/to/users' }
      let(:options)        { super().merge(qualified_name: qualified_name) }

      it { expect(middleware.qualified_name).to be == qualified_name }
    end
  end

  describe '#repository' do
    include_examples 'should define reader', :repository, -> { repository }
  end
end
