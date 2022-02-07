# frozen_string_literal: true

require 'cuprum/collections/loader/errors/middleware_error'

RSpec.describe Cuprum::Collections::Loader::Errors::MiddlewareError do
  subject(:error) { described_class.new(**constructor_options) }

  let(:middleware) { 'Data::Middleware::EntityMiddleware' }
  let(:constructor_options) do
    { middleware: middleware }
  end

  describe '::TYPE' do
    include_examples 'should define constant',
      :TYPE,
      'librum/data/errors/middleware_error'
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:attribute_name, :message, :middleware, :options)
    end
  end

  describe '#as_json' do
    let(:expected) do
      {
        'data'    => {
          'attribute_name' => nil,
          'middleware'     => middleware,
          'options'        => 'nil'
        },
        'message' => error.message,
        'type'    => error.type
      }
    end

    it { expect(error.as_json).to be == expected }

    context 'when initialized with an attribute name' do
      let(:attribute_name) { 'name' }
      let(:constructor_options) do
        super().merge(attribute_name: attribute_name)
      end
      let(:expected) do
        {
          'data'    => {
            'attribute_name' => attribute_name,
            'middleware'     => middleware,
            'options'        => 'nil'
          },
          'message' => error.message,
          'type'    => error.type
        }
      end

      it { expect(error.as_json).to be == expected }
    end

    context 'when initialized with options: value' do
      let(:options) { { 'key' => 'value' } }
      let(:constructor_options) { super().merge(options: options) }
      let(:expected) do
        {
          'data'    => {
            'attribute_name' => nil,
            'middleware'     => middleware,
            'options'        => options.inspect
          },
          'message' => error.message,
          'type'    => error.type
        }
      end

      it { expect(error.as_json).to be == expected }
    end
  end

  describe '#attribute_name' do
    include_examples 'should define reader', :attribute_name, nil

    context 'when initialized with an attribute name' do
      let(:attribute_name) { 'name' }
      let(:constructor_options) do
        super().merge(attribute_name: attribute_name)
      end

      it { expect(error.attribute_name).to be == attribute_name }
    end
  end

  describe '#message' do
    let(:expected) { "unable to generate middleware #{middleware}" }

    include_examples 'should define reader', :message, -> { expected }

    context 'when initialized with an attribute name' do
      let(:attribute_name) { 'name' }
      let(:constructor_options) do
        super().merge(attribute_name: attribute_name)
      end
      let(:expected) do
        "#{super()} for attribute #{attribute_name.inspect}"
      end

      it { expect(error.message).to be == expected }
    end

    context 'when initialized with message: value' do
      let(:message) { 'Something went wrong' }
      let(:constructor_options) do
        super().merge(message: message)
      end
      let(:expected) do
        "#{super()}: #{message}"
      end

      it { expect(error.message).to be == expected }
    end

    context 'when initialized with options: value' do
      let(:options)             { { 'key' => 'value' } }
      let(:constructor_options) { super().merge(options: options) }
      let(:expected) do
        "#{super()} with options #{options.inspect}"
      end

      it { expect(error.message).to be == expected }
    end

    context 'when initialized with multiple options' do
      let(:attribute_name) { 'name' }
      let(:message)        { 'Something went wrong' }
      let(:options)        { { 'key' => 'value' } }
      let(:constructor_options) do
        super().merge(
          attribute_name: attribute_name,
          message:        message,
          options:        options
        )
      end
      let(:expected) do
        "#{super()} for attribute #{attribute_name.inspect} with options" \
          " #{options.inspect}: #{message}"
      end

      it { expect(error.message).to be == expected }
    end
  end

  describe '#middleware' do
    include_examples 'should define reader', :middleware, -> { middleware }
  end

  describe '#options' do
    include_examples 'should define reader', :options, nil

    context 'when initialized with options: value' do
      let(:options)             { { 'key' => 'value' } }
      let(:constructor_options) { super().merge(options: options) }

      it { expect(error.options).to be == options }
    end
  end

  describe '#type' do
    include_examples 'should define reader', :type, -> { described_class::TYPE }
  end
end
