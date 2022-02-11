# frozen_string_literal: true

require 'cuprum/collections/loader/errors/parse_error'

RSpec.describe Cuprum::Collections::Loader::Errors::ParseError do
  subject(:error) { described_class.new(**constructor_options) }

  let(:format)    { :json }
  let(:raw_value) { Object.new.freeze }
  let(:constructor_options) do
    {
      format:    format,
      raw_value: raw_value
    }
  end

  describe '::TYPE' do
    include_examples 'should define constant',
      :TYPE,
      'cuprum/collections/loader/errors/parse_error'
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:format, :message, :raw_value)
    end
  end

  describe '#as_json' do
    let(:expected) do
      {
        'data'    => {
          'format'    => format.to_s,
          'raw_value' => raw_value.inspect
        },
        'message' => error.message,
        'type'    => error.type
      }
    end

    it { expect(error.as_json).to be == expected }
  end

  describe '#format' do
    include_examples 'should define reader', :format, -> { format }
  end

  describe '#message' do
    let(:expected) do
      "Unable to parse object as #{format}: #{raw_value.inspect}"
    end

    include_examples 'should define reader', :message, -> { be == expected }

    context 'when initialized with message: value' do
      let(:message) { 'Something went wrong.' }
      let(:constructor_options) do
        super().merge(message: message)
      end

      it { expect(error.message).to be == message }
    end
  end

  describe '#raw_value' do
    include_examples 'should define reader', :raw_value, -> { raw_value }
  end

  describe '#type' do
    include_examples 'should define reader', :type, -> { described_class::TYPE }
  end
end
