# frozen_string_literal: true

require 'support/middleware/titleize'

RSpec.describe Spec::Support::Middleware::Titleize do
  subject(:middleware) { described_class.new(attribute_name) }

  let(:attribute_name) { 'name' }

  describe '#call' do
    let(:next_command) do
      Cuprum::Command.new { |attributes:| attributes.merge('ok' => true) }
    end

    describe 'with attributes: an empty Hash' do
      let(:attributes)     { {} }
      let(:expected_value) { { 'name' => '', 'ok' => true } }

      it 'should return a passing result' do
        expect(middleware.call(next_command, attributes: attributes))
          .to be_a_passing_result
          .with_value(expected_value)
      end
    end

    describe 'with attributes: a Hash with a name' do
      let(:attributes)     { { 'name' => 'pYrA mAnIa' } }
      let(:expected_value) { { 'name' => 'Pyra Mania', 'ok' => true } }

      it 'should return a passing result' do
        expect(middleware.call(next_command, attributes: attributes))
          .to be_a_passing_result
          .with_value(expected_value)
      end
    end
  end
end
