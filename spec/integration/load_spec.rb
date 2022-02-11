# frozen_string_literal: true

require 'cuprum/collections/basic/collection'
require 'cuprum/collections/basic/repository'
require 'stannum/constraints/anything'

require 'cuprum/collections/loader/load'

RSpec.describe Cuprum::Collections::Loader::Load do
  subject(:command) do
    described_class.new(data_path: data_path, repository: repository)
  end

  let(:root_path) { __dir__.sub(%r{/spec/integration\z}, '') }
  let(:data_path) { File.join(root_path, 'spec/support/data') }
  let(:repository) do
    Cuprum::Collections::Basic::Repository.new
  end

  describe '#call' do
    describe 'with books data' do
      let(:data) { [] }
      let(:collection) do
        repository.build(
          collection_name:  'books',
          data:             data,
          default_contract: Stannum::Constraints::Anything.new
        )
      end
      let(:loaded_entities) do
        [
          {
            'id'     => 0,
            'title'  => 'How To Make Friends And Influence People:' \
                        ' Necromancy, Enchantment, And You',
            'author' => 'Abby Normal',
            'review' => <<~RAW.strip
              An excellent reference! Just don't try and combine the two disciplines.
              Trust me on this.

              -- Edric the Formerly Alive
            RAW
          },
          {
            'id'     => 1,
            'title'  => 'The Winter Of Our Discontent',
            'author' => 'Pyra Mania',
            'review' => <<~RAW.strip
              The first half is an invaluable treatise on Fire magic. The second half is
              a dubiously sane plan for halting the cycle of seasons. Would recommend, but
              with caution.
            RAW
          },
          {
            'id'     => 2,
            'title'  => 'Burning Love',
            'author' => 'Pyra Mania',
            'review' => <<~RAW.strip
              I would tell you to burn this, but it might like it. Bury it in the desert.
              Wear gloves.
            RAW
          }
        ]
      end
      let(:expected_value) do
        loaded_entities.map { |entity| ['create', entity] }
      end
      let(:expected_entities) { loaded_entities }

      it 'should return a passing result' do
        expect(command.call(collection: collection))
          .to be_a_passing_result
          .with_value(expected_value)
      end

      it 'should update the collection' do
        command.call(collection: collection)

        expect(collection.find_matching.call.value.to_a)
          .to be == expected_entities
      end

      context 'when the collection already has data' do
        let(:matching_entities) do
          [
            {
              'id'     => 1,
              'title'  => 'The Winter Of Our Discontent',
              'review' => 'Non-stop Chills!'
            },
            {
              'id'    => 2,
              'title' => 'Burning Love'
            }
          ]
        end
        let(:existing_entity) do
          {
            'id'     => 3,
            'title'  => 'Mysterious Memoirs',
            'author' => 'Ann Onymous',
            'review' => ''
          }
        end
        let(:expected_entities) do
          [*super(), existing_entity]
        end
        let(:expected_value) do
          loaded_entities.map do |entity|
            [entity['id'] == 0 ? 'create' : 'update', entity]
          end
        end

        before(:example) do
          collection.insert_one.call(entity: existing_entity)

          matching_entities.each do |matching_entity|
            collection.insert_one.call(entity: matching_entity)
          end
        end

        it 'should return a passing result' do
          expect(command.call(collection: collection))
            .to be_a_passing_result
            .with_value(expected_value)
        end

        it 'should update the collection' do
          command.call(collection: collection)

          expect(collection.find_matching.call(order: 'id').value.to_a)
            .to be == expected_entities
        end
      end
    end

    describe 'with users data' do
      let(:relative_path) { '/authentication/users' }
      let(:data)          { [] }
      let(:collection) do
        repository.build(
          collection_name:  'users',
          data:             data,
          default_contract: Stannum::Constraints::Anything.new
        )
      end
      let(:loaded_entities) do
        [
          {
            'id'                 => 0,
            'name'               => 'Abby Normal',
            'encrypted_password' => 'kwfspjsxyjns'
          },
          {
            'id'                 => 1,
            'name'               => 'Pyra Mania',
            'encrypted_password' => 'gzws'
          }
        ]
      end
      let(:expected_value) do
        loaded_entities.map { |entity| ['create', entity] }
      end
      let(:expected_entities) { loaded_entities }

      it 'should return a passing result' do
        expect(
          command.call(collection: collection, relative_path: relative_path)
        )
          .to be_a_passing_result
          .with_value(expected_value)
      end

      it 'should update the collection' do
        command.call(collection: collection, relative_path: relative_path)

        expect(collection.find_matching.call.value.to_a)
          .to be == expected_entities
      end

      describe 'with credentials data' do
        let(:credentials_collection) do
          repository.build(
            collection_name:  'credentials',
            data:             [],
            default_contract: Stannum::Constraints::Anything.new,
            qualified_name:   'authentication/credentials'
          )
        end
        let(:loaded_entities) do
          [
            {
              'id'      => 0,
              'api_key' => '12345',
              'user'    => {
                'id'                 => 0,
                'name'               => 'Abby Normal',
                'encrypted_password' => 'kwfspjsxyjns'
              }
            },
            {
              'id'      => 1,
              'api_key' => '67890',
              'user'    => {
                'id'                 => 1,
                'name'               => 'Pyra Mania',
                'encrypted_password' => 'gzws'
              }
            }
          ]
        end
        let(:expected_value) do
          loaded_entities.map { |entity| ['create', entity] }
        end
        let(:expected_entities) { loaded_entities }

        before(:example) do
          command.call(collection: collection, relative_path: relative_path)
        end

        it 'should return a passing result' do
          expect(command.call(collection: credentials_collection))
            .to be_a_passing_result
            .with_value(expected_value)
        end

        it 'should update the collection' do
          command.call(collection: credentials_collection)

          expect(
            credentials_collection.find_matching.call(order: 'id').value.to_a
          )
            .to be == expected_entities
        end
      end
    end
  end
end
