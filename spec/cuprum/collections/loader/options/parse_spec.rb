# frozen_string_literal: true

require 'cuprum/collections/loader/options/parse'

RSpec.describe Cuprum::Collections::Loader::Options::Parse do
  subject(:command) { described_class.new }

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  describe '#call' do
    shared_examples 'should validate the middleware class' do
      describe 'when the middleware class is an Object' do
        let(:middleware_value) { Object.new.freeze }
        let(:expected_error) do
          Cuprum::Collections::Loader::Errors::MiddlewareError.new(
            attribute_name: attribute_name,
            middleware:     middleware_value,
            options:        middleware_options
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
          elsif middleware_options.empty?
            <<~MESSAGE.strip
              wrong constant name invalid string

                      Object.const_get(class_name).new(*args)
                            ^^^^^^^^^^
            MESSAGE
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
            options:        middleware_options,
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
          elsif middleware_options.empty?
            <<~MESSAGE.strip
              uninitialized constant InvalidString

                      Object.const_get(class_name).new(*args)
                            ^^^^^^^^^^
            MESSAGE
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
            options:        middleware_options,
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
            options:        {},
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
              .and(have_attributes(attribute_name: attribute_name, options: {}))
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
              .and(have_attributes(attribute_name: attribute_name, options: {}))
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
                options:        { 'index' => 0 }
              )
            ),
            be_a(Spec::MiddlewareTwo).and(
              have_attributes(
                attribute_name: attribute_name,
                options:        { 'index' => 1 }
              )
            ),
            be_a(Spec::MiddlewareThree).and(
              have_attributes(
                attribute_name: attribute_name,
                options:        { 'index' => 2 }
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
            options:        {},
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
              have_attributes(options: {})
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
              have_attributes(options: {})
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
              have_attributes(options: { 'index' => 0 })
            ),
            be_a(Spec::MiddlewareTwo).and(
              have_attributes(options: { 'index' => 1 })
            ),
            be_a(Spec::MiddlewareThree).and(
              have_attributes(options: { 'index' => 2 })
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

    describe 'with a hash with entity and attribute middleware' do
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
              have_attributes(options: { 'index' => 0 })
            ),
            be_a(Spec::MiddlewareTwo).and(
              have_attributes(options: { 'index' => 1 })
            ),
            be_a(Spec::MiddlewareThree).and(
              have_attributes(options: { 'index' => 2 })
            ),
            be_a(Cuprum::Collections::Loader::Middleware::AttributeMiddleware)
              .and(
                have_attributes(attribute_name: attribute_name, options: {})
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
  end
end
