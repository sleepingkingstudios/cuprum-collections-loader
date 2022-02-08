# frozen_string_literal: true

require 'cuprum/collections/basic/collection'
require 'stannum/constraints/anything'

require 'cuprum/collections/loader/load'
require 'cuprum/collections/loader/observer'

RSpec.describe Cuprum::Collections::Loader::Observer do
  subject(:observer) { described_class.new }

  describe '#update' do
    let(:root_path) { __dir__.sub(%r{/spec/integration\z}, '') }
    let(:data_path) { File.join(root_path, 'spec/support/data') }
    let(:collection) do
      Cuprum::Collections::Basic::Collection.new(
        collection_name:  'books',
        data:             [],
        default_contract: Stannum::Constraints::Anything.new
      )
    end
    let(:command) do
      Cuprum::Collections::Loader::Load.new(data_path: data_path)
    end
    let(:expected_output) do
      <<~OUTPUT
        Loading 3 books from #{File.join(data_path, 'books')}
        - Successfully created book with title "How To Make Friends And Influence People: Necromancy, Enchantment, And You"
        - Successfully created book with title "The Winter Of Our Discontent"
        - Successfully created book with title "Burning Love"
      OUTPUT
    end

    before(:example) { command.add_observer(observer) }

    it 'should write notifications to STDOUT' do
      expect { command.call(collection: collection) }
        .to output(expected_output)
        .to_stdout
    end

    context 'when the entities already exist' do
      let(:existing_entities) do
        [
          {
            'id'    => 0,
            'title' => 'How To Make Friends And Influence People: Necromancy,' \
                       ' Enchantment, And You'
          },
          {
            'id'    => 1,
            'title' => 'The Winter Of Our Discontent'
          },
          {
            'id'    => 2,
            'title' => 'Burning Love'
          }
        ]
      end
      let(:expected_output) do
        <<~OUTPUT
          Loading 3 books from #{File.join(data_path, 'books')}
          - Successfully updated book with title "How To Make Friends And Influence People: Necromancy, Enchantment, And You"
          - Successfully updated book with title "The Winter Of Our Discontent"
          - Successfully updated book with title "Burning Love"
        OUTPUT
      end

      before(:example) do
        existing_entities.each do |entity|
          collection.insert_one.call(entity: entity)
        end
      end

      it 'should write notifications to STDOUT' do
        expect { command.call(collection: collection) }
          .to output(expected_output)
          .to_stdout
      end
    end
  end
end
