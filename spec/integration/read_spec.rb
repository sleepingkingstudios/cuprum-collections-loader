# frozen_string_literal: true

require 'cuprum/collections/loader'

RSpec.describe Cuprum::Collections::Loader::Read do
  subject(:command) { described_class.new(data_path: data_path) }

  let(:root_path) { __dir__.sub(%r{/spec/integration}, '') }
  let(:data_path) { File.join(root_path, 'spec/support/data') }

  describe '#call' do
    describe 'with books data' do
      let(:relative_path) { '/books' }
      let(:expected_data) do
        [
          {
            'title'  => 'How To Make Friends And Influence People:' \
                        ' Necromancy, Enchantment, and You',
            'author' => 'Abby Normal',
            'review' => <<~RAW.strip
              An excellent reference! Just don't try and combine the two disciplines.
              Trust me on this.

              -- Edric the Formerly Alive
            RAW
          },
          {
            'title'  => 'The Winter Of Our Discontent',
            'author' => 'Pyra Mania',
            'review' => <<~RAW.strip
              The first half is an invaluable treatise on Fire magic. The second half is
              a dubiously sane plan for halting the cycle of seasons. Would recommend, but
              with caution.
            RAW
          },
          {
            'title'  => 'Burning Love',
            'author' => 'Pyra Mania',
            'review' => <<~RAW.strip
              I would tell you to burn this, but it might like it. Bury it in the desert.
              Wear gloves.
            RAW
          }
        ]
      end
      let(:expected_options) do
        {
          'find_by'    => 'slug',
          'middleware' => [
            'Spec::Support::Middleware::GenerateSlug'
          ],
          'review'     => {
            'multiline' => true
          }
        }
      end
      let(:expected_value) { [expected_data, expected_options] }

      it 'should return a passing result' do
        expect(command.call(relative_path: relative_path))
          .to be_a_passing_result
          .with_value(expected_value)
      end
    end

    describe 'with users data' do
      let(:relative_path) { '/authentication/users' }
      let(:expected_data) do
        [
          {
            'name'     => 'Abby Normal',
            'password' => 'Frankenstein'
          },
          {
            'name'     => 'Pyra Mania',
            'password' => 'Burn!!!'
          }
        ]
      end
      let(:expected_options) do
        {
          'middleware' => [
            'Spec::Support::Middleware::EncryptPassword'
          ]
        }
      end
      let(:expected_value) { [expected_data, expected_options] }

      it 'should return a passing result' do
        expect(command.call(relative_path: relative_path))
          .to be_a_passing_result
          .with_value(expected_value)
      end
    end
  end
end
