# frozen_string_literal: true

require 'yaml'

require 'cuprum/collections/loader'

require 'support/middleware/encrypt_password'
require 'support/middleware/titleize'

RSpec.describe Cuprum::Collections::Loader::Options::Parse do
  subject(:command) { described_class.new }

  let(:root_path) { __dir__.sub(%r{/spec/integration/options\z}, '') }
  let(:data_path) { File.join(root_path, 'spec/support/data') }

  describe '#call' do
    let(:options) do
      raw = File.read(options_path)

      YAML.safe_load(raw)
    end

    describe 'with books options' do
      let(:options_path) { File.join(data_path, 'books_options.yml') }
      let(:expected_value) do
        {
          'find_by'    => 'title',
          'middleware' => [
            be_a(Spec::Support::Middleware::Titleize).and(
              have_attributes(
                attribute_name: 'title',
                options:        {}
              )
            )
          ],
          'review'     => { 'multiline' => true },
          'title'      => {}
        }
      end

      it 'should return a passing result' do
        expect(command.call(options: options))
          .to be_a_passing_result
          .with_value(deep_match(expected_value))
      end
    end

    describe 'with users options' do
      let(:options_path) do
        File.join(data_path, 'authentication/users/_options.yml')
      end
      let(:expected_value) do
        {
          'middleware' => [
            be_a(Spec::Support::Middleware::EncryptPassword).and(
              have_attributes(options: {})
            )
          ]
        }
      end

      it 'should return a passing result' do
        expect(command.call(options: options))
          .to be_a_passing_result
          .with_value(deep_match(expected_value))
      end
    end
  end
end
