# frozen_string_literal: true

require 'cuprum'

require 'cuprum/collections/loader/options'

module Cuprum::Collections::Loader::Options
  # Parses data options and resolves metadata.
  class Parse < Cuprum::Command
    private

    def create_middleware(class_name, attribute_name = nil, **options) # rubocop:disable Metrics/MethodLength
      step { validate_class_name(class_name, attribute_name, **options) }

      args = attribute_name ? [attribute_name] : []

      if options.empty?
        Object.const_get(class_name).new(*args)
      else
        Object.const_get(class_name).new(*args, **options)
      end
    rescue ArgumentError, NameError => exception
      failure(
        middleware_error(
          attribute_name: attribute_name,
          middleware:     class_name,
          options:        options,
          message:        exception.message
        )
      )
    end

    def middleware?(option)
      option.is_a?(Hash) && option.key?('middleware')
    end

    def middleware_error(
      middleware:,
      attribute_name: nil,
      message:        nil,
      options:        nil
    )
      Cuprum::Collections::Loader::Errors::MiddlewareError.new(
        attribute_name: attribute_name,
        message:        message,
        middleware:     middleware,
        options:        options
      )
    end

    def parse_middleware(middleware, attribute_name: nil) # rubocop:disable Metrics/MethodLength
      case middleware
      when NilClass
        []
      when Array
        # middleware: ['Middleware::ClassName', 'Middleware::ClassName']
        middleware.map do |class_name|
          step { create_middleware(class_name, attribute_name) }
        end
      when Hash
        # middleware: { 'Middleware::ClassName' => { ... } }
        middleware.map do |class_name, options|
          step { validate_options(class_name, attribute_name, options) }

          step { create_middleware(class_name, attribute_name, **options) }
        end
      else
        # middleware: 'Middleware::ClassName'
        [step { create_middleware(middleware, attribute_name) }]
      end
    end

    def parse_option(attribute_name:, attribute_options:)
      return [attribute_options, []] unless middleware?(attribute_options)

      attribute_options = attribute_options.dup
      middleware        = attribute_options.delete('middleware')
      middleware        = step do
        parse_middleware(middleware, attribute_name: attribute_name)
      end

      [attribute_options, middleware]
    end

    def process(options:) # rubocop:disable Metrics/MethodLength
      options    = options.dup
      middleware = options.delete('middleware')
      middleware = parse_middleware(middleware)

      options
        .to_h do |attribute_name, attribute_options|
          parsed_option, option_middleware = step do
            parse_option(
              attribute_name:    attribute_name,
              attribute_options: attribute_options
            )
          end

          middleware += option_middleware

          [attribute_name, parsed_option]
        end
        .merge('middleware' => middleware)
    end

    def validate_class_name(class_name, attribute_name, **options)
      return if !class_name.nil? && class_name.is_a?(String)

      failure(
        middleware_error(
          attribute_name: attribute_name,
          middleware:     class_name,
          options:        options
        )
      )
    end

    def validate_options(class_name, attribute_name, options)
      return if options.is_a?(Hash)

      failure(
        middleware_error(
          attribute_name: attribute_name,
          middleware:     class_name,
          options:        options,
          message:        'invalid options hash'
        )
      )
    end
  end
end
