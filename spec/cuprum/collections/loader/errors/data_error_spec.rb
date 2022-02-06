# frozen_string_literal: true

require 'cuprum/collections/loader/errors/data_error'

RSpec.describe Cuprum::Collections::Loader::Errors::DataError do
  subject(:error) { described_class.new(**constructor_options) }

  let(:format)       { :json }
  let(:parsed_value) { 'parsed value' }
  let(:raw_value)    { Object.new.freeze }
  let(:constructor_options) do
    {
      format:       format,
      parsed_value: parsed_value,
      raw_value:    raw_value
    }
  end

  describe '::TYPE' do
    include_examples 'should define constant',
      :TYPE,
      'librum/data/errors/data_error'
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:format, :message, :parsed_value, :raw_value)
    end
  end

  describe '#as_json' do
    let(:expected) do
      {
        'data'    => {
          'format'       => format.to_s,
          'parsed_value' => parsed_value.inspect,
          'raw_value'    => raw_value.inspect
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
      "Invalid #{format} data object:\n\n  raw_value:\n" \
        "#{tools.string_tools.indent(raw_value.inspect, 4)}" \
        "\n\n  parsed value:\n" \
        "#{tools.string_tools.indent(parsed_value.inspect, 4)}"
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
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

  describe '#parsed_value' do
    include_examples 'should define reader', :parsed_value, -> { parsed_value }
  end

  describe '#raw_value' do
    include_examples 'should define reader', :raw_value, -> { raw_value }
  end

  describe '#type' do
    include_examples 'should define reader', :type, -> { described_class::TYPE }
  end
end
