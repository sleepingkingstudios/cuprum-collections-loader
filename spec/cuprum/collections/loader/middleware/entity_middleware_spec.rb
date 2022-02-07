# frozen_string_literal: true

require 'base64'

require 'cuprum/collections/loader/middleware/entity_middleware'

RSpec.describe Cuprum::Collections::Loader::Middleware::EntityMiddleware do
  subject(:middleware) { described_class.new(**options) }

  let(:options) { {} }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_any_keywords
    end
  end

  describe '#call' do
    let(:attributes) { { 'name' => 'Alan Bradley' } }
    let(:next_command) do
      Cuprum::Command.new { |hsh| hsh.merge({ 'ok' => true }) }
    end
    let(:expected_value) do
      attributes.merge({ 'ok' => true })
    end

    it 'should define the method' do # rubocop:disable RSpec/ExampleLength
      expect(middleware)
        .to be_callable
        .with(1).argument
        .and_unlimited_arguments
        .and_any_keywords
        .and_a_block
    end

    it 'should return a passing result' do
      expect(middleware.call(next_command, attributes))
        .to be_a_passing_result
        .with_value(expected_value)
    end

    it 'should call the next command' do
      allow(next_command).to receive(:call)

      middleware.call(next_command, attributes)

      expect(next_command).to have_received(:call).with(attributes)
    end

    context 'with a middleware subclass' do
      let(:described_class) { Spec::ExampleMiddleware }
      let(:options)         { { key: 'slug', value: 'alan-bradley' } }
      let(:expected_value) do
        hsh       =
          attributes
          .merge({ 'slug' => 'alan-bradley' })
          .merge({ 'ok' => true })
        signature = Base64.encode64(hsh.inspect)

        hsh.merge({ 'signature' => signature })
      end

      # rubocop:disable RSpec/DescribedClass
      example_class 'Spec::ExampleMiddleware',
        Cuprum::Collections::Loader::Middleware::EntityMiddleware \
      do |klass|
        klass.define_method(:process) do |next_command, hsh|
          hsh = hsh.merge({ options[:key] => options[:value] })

          hsh       = step { super(next_command, hsh) }
          signature = Base64.encode64(hsh.inspect)

          hsh.merge({ 'signature' => signature })
        end
      end
      # rubocop:enable RSpec/DescribedClass

      it 'should return a passing result' do
        expect(middleware.call(next_command, attributes))
          .to be_a_passing_result
          .with_value(expected_value)
      end
    end
  end

  describe '#options' do
    include_examples 'should define reader', :options, -> { be == options }

    context 'when the middleware is initialized with options' do
      let(:options) { { key: 'value' } }

      it { expect(middleware.options).to be == options }
    end
  end
end
