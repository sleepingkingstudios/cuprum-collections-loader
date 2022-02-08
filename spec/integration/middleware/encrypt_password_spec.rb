# frozen_string_literal: true

require 'support/middleware/encrypt_password'

RSpec.describe Spec::Support::Middleware::EncryptPassword do
  subject(:middleware) { described_class.new }

  describe '#call' do
    let(:next_command) do
      Cuprum::Command.new { |attributes:| attributes.merge('ok' => true) }
    end

    describe 'with attributes: an empty Hash' do
      let(:attributes)     { {} }
      let(:expected_value) { { 'encrypted_password' => '', 'ok' => true } }

      it 'should return a passing result' do
        expect(middleware.call(next_command, attributes: attributes))
          .to be_a_passing_result
          .with_value(expected_value)
      end
    end

    describe 'with attributes: a Hash with a password' do
      let(:attributes) do
        {
          'name'     => 'Abby Normal',
          'password' => 'Frankenstein'
        }
      end
      let(:expected_value) do
        {
          'name'               => 'Abby Normal',
          'encrypted_password' => 'kwfspjsxyjns',
          'ok'                 => true
        }
      end

      it 'should return a passing result' do
        expect(middleware.call(next_command, attributes: attributes))
          .to be_a_passing_result
          .with_value(expected_value)
      end
    end
  end
end
