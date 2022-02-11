# frozen_string_literal: true

require 'cuprum/collections/basic/repository'

require 'cuprum/collections/loader/errors/collection_error'

RSpec.describe Cuprum::Collections::Loader::Errors::CollectionError do
  subject(:error) do
    described_class.new(qualified_name: qualified_name, repository: repository)
  end

  let(:qualified_name) { 'path/to/books' }
  let(:repository)     { Cuprum::Collections::Basic::Repository.new }

  describe '::TYPE' do
    include_examples 'should define constant',
      :TYPE,
      'cuprum/collections/loader/errors/collection_error'
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:qualified_name, :repository)
    end
  end

  describe '#as_json' do
    let(:expected) do
      {
        'data'    => {
          'collections'      => repository.keys,
          'qualified_name'   => qualified_name,
          'repository_class' => repository.class.name
        },
        'message' => error.message,
        'type'    => error.type
      }
    end

    include_examples 'should define reader', :as_json, -> { be == expected }

    context 'when the repository has many collections' do
      before(:example) do
        repository.build(collection_name: 'books')
        repository.build(
          collection_name: 'tomes',
          qualified_name:  'path/to/tomes'
        )
        repository.build(collection_name: 'grimoires')
      end

      include_examples 'should define reader', :as_json, -> { be == expected }
    end
  end

  describe '#message' do
    let(:expected) do
      "collection not found with qualified name #{qualified_name.inspect}"
    end

    include_examples 'should define reader', :message, -> { expected }
  end

  describe '#qualified_name' do
    include_examples 'should define reader',
      :qualified_name,
      -> { qualified_name }
  end

  describe '#repository' do
    include_examples 'should define reader',
      :repository,
      -> { repository }
  end

  describe '#type' do
    include_examples 'should define reader', :type, described_class::TYPE
  end
end
