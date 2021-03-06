# frozen_string_literal: true

require 'cuprum/collections/repository'

require 'cuprum/collections/loader/options/parse'

RSpec.describe Cuprum::Collections::Loader::Options::Parse do
  subject(:command) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:repository)
    end
  end

  describe '#call' do
    shared_examples 'should validate the middleware class' do
      describe 'when the middleware class is an Object' do
        let(:middleware_value) { Object.new.freeze }
        let(:expected_error) do
          Cuprum::Collections::Loader::Errors::MiddlewareError.new(
            attribute_name: attribute_name,
            middleware:     middleware_value,
            options:        tools
                            .hash_tools
                            .convert_keys_to_symbols(middleware_options)
          )
        end

        it 'should return a failing result' do
          expect(command.call(options: options))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      describe 'when the middleware class is an invalid String' do
        let(:middleware_value) { 'invalid string' }
        let(:expected_message) do
          # :nocov:
          if RUBY_VERSION < '3.1.0'
            'wrong constant name invalid string'
          else
            <<~MESSAGE.strip
              wrong constant name invalid string

                    Object.const_get(class_name).new(*args, **options)
                          ^^^^^^^^^^
            MESSAGE
          end
          # :nocov:
        end
        let(:expected_error) do
          Cuprum::Collections::Loader::Errors::MiddlewareError.new(
            attribute_name: attribute_name,
            middleware:     middleware_value,
            options:        tools
                            .hash_tools
                            .convert_keys_to_symbols(middleware_options)
                            .merge(repository: repository),
            message:        expected_message
          )
        end

        it 'should return a failing result' do
          expect(command.call(options: options))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      describe 'when the middleware class is an invalid class name' do
        let(:middleware_value) { 'InvalidString' }
        let(:expected_message) do
          # :nocov:
          if RUBY_VERSION < '3.1.0'
            'uninitialized constant InvalidString'
          else
            <<~MESSAGE.strip
              uninitialized constant InvalidString

                    Object.const_get(class_name).new(*args, **options)
                          ^^^^^^^^^^
            MESSAGE
          end
          # :nocov:
        end
        let(:expected_error) do
          Cuprum::Collections::Loader::Errors::MiddlewareError.new(
            attribute_name: attribute_name,
            middleware:     middleware_value,
            options:        tools
                            .hash_tools
                            .convert_keys_to_symbols(middleware_options)
                            .merge(repository: repository),
            message:        expected_message
          )
        end

        it 'should return a failing result' do
          expect(command.call(options: options))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end
    end

    shared_examples 'should validate the middleware' do
      describe 'with middleware: a value' do
        let(:middleware)         { middleware_value }
        let(:middleware_options) { {} }

        include_examples 'should validate the middleware class'
      end

      describe 'with middleware: an Array' do
        let(:middleware)         { [middleware_value] }
        let(:middleware_options) { {} }

        include_examples 'should validate the middleware class'
      end

      describe 'with middleware: an Object' do
        let(:middleware_options) { { 'key' => 'value' } }
        let(:middleware)         { { middleware_value => middleware_options } }

        include_examples 'should validate the middleware class'

        describe 'when the options are invalid' do
          let(:middleware_value) do
            'Cuprum::Collections::Loader::Middleware::EntityMiddleware'
          end
          let(:middleware_options) { Object.new.freeze }
          let(:expected_error) do
            Cuprum::Collections::Loader::Errors::MiddlewareError.new(
              attribute_name: attribute_name,
              middleware:     middleware_value,
              options:        middleware_options,
              message:        'invalid options hash'
            )
          end

          it 'should return a failing result' do
            expect(command.call(options: options))
              .to be_a_failing_result
              .with_error(expected_error)
          end
        end
      end
    end

    let(:repository) { instance_double(Cuprum::Collections::Repository) }
    let(:require_proxy) do
      class_double(Kernel, require: nil)
    end
    let(:constructor_options) do
      super().merge(require_proxy: require_proxy, repository: repository)
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end

    it 'should define the method' do
      expect(command)
        .to be_callable
        .with(0).arguments
        .and_keywords(:options)
    end

    describe 'with an empty Hash' do
      let(:options)        { {} }
      let(:expected_value) { { 'middleware' => [] } }

      it 'should return a passing result' do
        expect(command.call(options: options))
          .to be_a_passing_result
          .with_value(expected_value)
      end
    end

    describe 'with a Hash with non-attribute values' do
      let(:options)        { { 'find_by' => 'slug' } }
      let(:expected_value) { options.merge('middleware' => []) }

      it 'should return a passing result' do
        expect(command.call(options: options))
          .to be_a_passing_result
          .with_value(expected_value)
      end
    end

    describe 'with a Hash with attribute values' do
      let(:options) do
        {
          'name'        => {},
          'description' => { 'multiline' => true }
        }
      end
      let(:expected_value) { options.merge('middleware' => []) }

      it 'should return a passing result' do
        expect(command.call(options: options))
          .to be_a_passing_result
          .with_value(expected_value)
      end
    end

    describe 'with a Hash with attribute middleware' do
      let(:attribute_name) { 'name' }
      let(:middleware)     { [] }
      let(:options) do
        {
          'name' => {
            'middleware' => middleware,
            'multiline'  => true
          }
        }
      end
      let(:expected_middleware) { [] }
      let(:expected_value) do
        {
          'middleware' => expected_middleware,
          'name'       => { 'multiline' => true }
        }
      end

      include_examples 'should validate the middleware'

      describe 'with middleware: nil' do
        let(:middleware) { nil }

        it 'should return a passing result' do
          expect(command.call(options: options))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end

      describe 'with middleware: an empty Array' do
        let(:middleware) { [] }

        it 'should return a passing result' do
          expect(command.call(options: options))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end

      describe 'with middleware: an empty Object' do
        let(:middleware) { {} }

        it 'should return a passing result' do
          expect(command.call(options: options))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end

      describe 'with middleware: an entity middleware class name' do
        let(:middleware) do
          'Cuprum::Collections::Loader::Middleware::EntityMiddleware'
        end
        let(:expected_error) do
          Cuprum::Collections::Loader::Errors::MiddlewareError.new(
            attribute_name: attribute_name,
            middleware:     middleware,
            options:        { repository: repository },
            message:        'wrong number of arguments (given 1, expected 0)'
          )
        end

        it 'should return a failing result' do
          expect(command.call(options: options))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      describe 'with middleware: a valid class name' do
        let(:middleware) do
          'Cuprum::Collections::Loader::Middleware::AttributeMiddleware'
        end
        let(:expected_middleware) do
          [
            be_a(Cuprum::Collections::Loader::Middleware::AttributeMiddleware)
              .and(
                have_attributes(
                  attribute_name: attribute_name,
                  options:        { repository: repository }
                )
              )
          ]
        end

        it 'should return a passing result' do
          expect(command.call(options: options))
            .to be_a_passing_result
            .with_value(deep_match(expected_value))
        end
      end

      describe 'with middleware: an Array of valid class names' do
        let(:middleware) do
          Array.new(3) do
            'Cuprum::Collections::Loader::Middleware::AttributeMiddleware'
          end
        end
        let(:expected_middleware) do
          Array.new(3) do
            be_a(Cuprum::Collections::Loader::Middleware::AttributeMiddleware)
              .and(
                have_attributes(
                  attribute_name: attribute_name,
                  options:        { repository: repository }
                )
              )
          end
        end

        it 'should return a passing result' do
          expect(command.call(options: options))
            .to be_a_passing_result
            .with_value(deep_match(expected_value))
        end
      end

      describe 'with middleware: an Hash of valid class names and options' do
        let(:middleware) do
          {
            'Spec::MiddlewareOne'   => { 'index' => 0 },
            'Spec::MiddlewareTwo'   => { 'index' => 1 },
            'Spec::MiddlewareThree' => { 'index' => 2 }
          }
        end
        let(:expected_middleware) do
          [
            be_a(Spec::MiddlewareOne).and(
              have_attributes(
                attribute_name: attribute_name,
                options:        {
                  index:      0,
                  repository: repository
                }
              )
            ),
            be_a(Spec::MiddlewareTwo).and(
              have_attributes(
                attribute_name: attribute_name,
                options:        {
                  index:      1,
                  repository: repository
                }
              )
            ),
            be_a(Spec::MiddlewareThree).and(
              have_attributes(
                attribute_name: attribute_name,
                options:        {
                  index:      2,
                  repository: repository
                }
              )
            )
          ]
        end

        example_class 'Spec::MiddlewareOne',
          Cuprum::Collections::Loader::Middleware::AttributeMiddleware
        example_class 'Spec::MiddlewareTwo',
          Cuprum::Collections::Loader::Middleware::AttributeMiddleware
        example_class 'Spec::MiddlewareThree',
          Cuprum::Collections::Loader::Middleware::AttributeMiddleware

        it 'should return a passing result' do
          expect(command.call(options: options))
            .to be_a_passing_result
            .with_value(deep_match(expected_value))
        end
      end
    end

    describe 'with a Hash with entity middleware' do
      let(:attribute_name) { nil }
      let(:middleware)     { [] }
      let(:options) do
        {
          'middleware' => middleware,
          'name'       => { 'multiline' => true }
        }
      end
      let(:expected_middleware) { [] }
      let(:expected_value) do
        {
          'middleware' => expected_middleware,
          'name'       => { 'multiline' => true }
        }
      end

      include_examples 'should validate the middleware'

      describe 'with middleware: nil' do
        let(:middleware) { nil }

        it 'should return a passing result' do
          expect(command.call(options: options))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end

      describe 'with middleware: an empty Array' do
        let(:middleware) { [] }

        it 'should return a passing result' do
          expect(command.call(options: options))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end

      describe 'with middleware: an empty Object' do
        let(:middleware) { {} }

        it 'should return a passing result' do
          expect(command.call(options: options))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end

      describe 'with middleware: an attribute middleware class name' do
        let(:middleware) do
          'Cuprum::Collections::Loader::Middleware::AttributeMiddleware'
        end
        let(:expected_error) do
          Cuprum::Collections::Loader::Errors::MiddlewareError.new(
            attribute_name: attribute_name,
            middleware:     middleware,
            options:        { repository: repository },
            message:        'wrong number of arguments (given 0, expected 1)'
          )
        end

        it 'should return a failing result' do
          expect(command.call(options: options))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      describe 'with middleware: a valid class name' do
        let(:middleware) do
          'Cuprum::Collections::Loader::Middleware::EntityMiddleware'
        end
        let(:expected_middleware) do
          [
            be_a(Cuprum::Collections::Loader::Middleware::EntityMiddleware).and(
              have_attributes(
                options: { repository: repository }
              )
            )
          ]
        end

        it 'should return a passing result' do
          expect(command.call(options: options))
            .to be_a_passing_result
            .with_value(deep_match(expected_value))
        end
      end

      describe 'with middleware: an Array of valid class names' do
        let(:middleware) do
          Array.new(3) do
            'Cuprum::Collections::Loader::Middleware::EntityMiddleware'
          end
        end
        let(:expected_middleware) do
          Array.new(3) do
            be_a(Cuprum::Collections::Loader::Middleware::EntityMiddleware).and(
              have_attributes(options: { repository: repository })
            )
          end
        end

        it 'should return a passing result' do
          expect(command.call(options: options))
            .to be_a_passing_result
            .with_value(deep_match(expected_value))
        end
      end

      describe 'with middleware: an Hash of valid class names and options' do
        let(:middleware) do
          {
            'Spec::MiddlewareOne'   => { 'index' => 0 },
            'Spec::MiddlewareTwo'   => { 'index' => 1 },
            'Spec::MiddlewareThree' => { 'index' => 2 }
          }
        end
        let(:expected_middleware) do
          [
            be_a(Spec::MiddlewareOne).and(
              have_attributes(
                options: {
                  index:      0,
                  repository: repository
                }
              )
            ),
            be_a(Spec::MiddlewareTwo).and(
              have_attributes(
                options: {
                  index:      1,
                  repository: repository
                }
              )
            ),
            be_a(Spec::MiddlewareThree).and(
              have_attributes(
                options: {
                  index:      2,
                  repository: repository
                }
              )
            )
          ]
        end

        example_class 'Spec::MiddlewareOne',
          Cuprum::Collections::Loader::Middleware::EntityMiddleware
        example_class 'Spec::MiddlewareTwo',
          Cuprum::Collections::Loader::Middleware::EntityMiddleware
        example_class 'Spec::MiddlewareThree',
          Cuprum::Collections::Loader::Middleware::EntityMiddleware

        it 'should return a passing result' do
          expect(command.call(options: options))
            .to be_a_passing_result
            .with_value(deep_match(expected_value))
        end
      end
    end

    describe 'with a Hash with entity and attribute middleware' do
      let(:attribute_name) { 'name' }
      let(:options) do
        {
          'middleware' => {
            'Spec::MiddlewareOne'   => { 'index' => 0 },
            'Spec::MiddlewareTwo'   => { 'index' => 1 },
            'Spec::MiddlewareThree' => { 'index' => 2 }
          },
          'name'       => {
            'middleware' => 'Cuprum::Collections::Loader::Middleware' \
                            '::AttributeMiddleware',
            'multiline'  => true
          }
        }
      end
      let(:expected_middleware) { [] }
      let(:expected_value) do
        {
          'middleware' => [
            be_a(Spec::MiddlewareOne).and(
              have_attributes(
                options: {
                  index:      0,
                  repository: repository
                }
              )
            ),
            be_a(Spec::MiddlewareTwo).and(
              have_attributes(
                options: {
                  index:      1,
                  repository: repository
                }
              )
            ),
            be_a(Spec::MiddlewareThree).and(
              have_attributes(
                options: {
                  index:      2,
                  repository: repository
                }
              )
            ),
            be_a(Cuprum::Collections::Loader::Middleware::AttributeMiddleware)
              .and(
                have_attributes(
                  attribute_name: attribute_name,
                  options:        { repository: repository }
                )
              )
          ],
          'name'       => { 'multiline' => true }
        }
      end

      example_class 'Spec::MiddlewareOne',
        Cuprum::Collections::Loader::Middleware::EntityMiddleware
      example_class 'Spec::MiddlewareTwo',
        Cuprum::Collections::Loader::Middleware::EntityMiddleware
      example_class 'Spec::MiddlewareThree',
        Cuprum::Collections::Loader::Middleware::EntityMiddleware

      it 'should return a passing result' do
        expect(command.call(options: options))
          .to be_a_passing_result
          .with_value(deep_match(expected_value))
      end
    end

    describe 'with a Hash with a require statement' do
      let(:options)        { { 'require' => 'path/to/require' } }
      let(:expected_value) { { 'middleware' => [] } }

      it 'should return a passing result' do
        expect(command.call(options: options))
          .to be_a_passing_result
          .with_value(expected_value)
      end

      it 'should call the require statement' do
        command.call(options: options)

        expect(require_proxy).to have_received(:require).with('path/to/require')
      end
    end

    describe 'with a Hash with multiple require statement' do
      let(:require_statements) do
        [
          'path/to/first',
          'path/to/second',
          'path/to/third'
        ]
      end
      let(:options) do
        { 'require' => require_statements }
      end
      let(:expected_value) { { 'middleware' => [] } }

      it 'should return a passing result' do
        expect(command.call(options: options))
          .to be_a_passing_result
          .with_value(expected_value)
      end

      it 'should call the require statements', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        command.call(options: options)

        require_statements.each do |require_path|
          expect(require_proxy)
            .to have_received(:require)
            .with(require_path)
        end
      end
    end
  end

  describe '#repository' do
    include_examples 'should define reader', :repository, nil

    context 'when initialized with repository: value' do
      let(:repository) { instance_double(Cuprum::Collections::Repository) }
      let(:constructor_options) do
        super().merge(repository: repository)
      end

      it { expect(command.repository).to be repository }
    end
  end

  describe '#require_proxy' do
    include_examples 'should define private reader', :require_proxy, Kernel
  end
end
