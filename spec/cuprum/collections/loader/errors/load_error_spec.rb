# frozen_string_literal: true

require 'cuprum/collections/loader/errors/load_error'

RSpec.describe Cuprum::Collections::Loader::Errors::LoadError do
  subject(:error) { described_class.new(**constructor_options) }

  let(:file_path) { 'path/to/file' }
  let(:constructor_options) do
    { file_path: file_path }
  end

  describe '::TYPE' do
    include_examples 'should define constant',
      :TYPE,
      'cuprum/collections/loader/errors/load_error'
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:file_path, :message)
    end
  end

  describe '#as_json' do
    let(:expected) do
      {
        'data'    => {
          'file_path' => file_path
        },
        'message' => error.message,
        'type'    => error.type
      }
    end

    it { expect(error.as_json).to be == expected }
  end

  describe '#file_path' do
    include_examples 'should define reader', :file_path, -> { file_path }
  end

  describe '#message' do
    let(:expected) { "Unable to load file #{file_path}" }

    include_examples 'should define reader', :message, -> { expected }

    context 'when initialized with message: value' do
      let(:message)  { 'try bouncing your query off the main deflector dish' }
      let(:expected) { "Unable to load file #{file_path}: #{message}" }
      let(:constructor_options) do
        super().merge(message: message)
      end

      it { expect(error.message).to be == expected }
    end
  end

  describe '#type' do
    include_examples 'should define reader', :type, -> { described_class::TYPE }
  end
end
