# frozen_string_literal: true

require 'cuprum/collections/repository'

require 'cuprum/collections/loader/middleware/attribute_middleware'

RSpec.describe Cuprum::Collections::Loader::Middleware::AttributeMiddleware do
  subject(:middleware) do
    described_class.new(attribute_name, repository: repository, **options)
  end

  let(:attribute_name) { 'name' }
  let(:repository)     { nil }
  let(:options)        { {} }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(1).argument
        .and_keywords(:repository)
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
      let(:options)         { { method_name: :upcase } }
      let(:expected_value) do
        {
          'name' => 'ALAN BRADLEY',
          'ok'   => true
        }
      end

      # rubocop:disable RSpec/DescribedClass
      example_class 'Spec::ExampleMiddleware',
        Cuprum::Collections::Loader::Middleware::AttributeMiddleware \
      do |klass|
        klass.define_method(:process) do |next_command, hsh|
          hsh = hsh.merge(
            attribute_name => hsh[attribute_name]&.send(options[:method_name])
          )

          super(next_command, hsh)
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

  describe '#attribute_name' do
    include_examples 'should define reader',
      :attribute_name,
      -> { be == attribute_name }
  end

  describe '#options' do
    let(:expected) { options.merge(repository: repository) }

    include_examples 'should define reader', :options, -> { be == expected }

    context 'when the middleware is initialized with a repository' do
      let(:repository) { instance_double(Cuprum::Collections::Repository) }
      let(:options)    { { repository: repository } }

      it { expect(middleware.options).to be == expected }
    end

    context 'when the middleware is initialized with options' do
      let(:options) { { key: 'value' } }

      it { expect(middleware.options).to be == expected }
    end
  end

  describe '#repository' do
    include_examples 'should define reader', :repository, nil

    context 'when the middleware is initialized with a repository' do
      let(:repository) { instance_double(Cuprum::Collections::Repository) }
      let(:options)    { { repository: repository } }

      it { expect(middleware.repository).to be repository }
    end
  end
end
