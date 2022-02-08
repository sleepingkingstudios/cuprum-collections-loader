# frozen_string_literal: true

require 'cuprum'

require 'cuprum/collections/loader/options'

module Cuprum::Collections::Loader::Options
  # Parses data options and resolves metadata.
  class Parse < Cuprum::Command # rubocop:disable Metrics/ClassLength
    # @overload initialize(repository: nil)
    #   @param repository [Cuprum::Collections::Repository] The repository used
    #     to query middleware data.
    def initialize(repository: nil, require_proxy: Kernel)
      super()

      @repository    = repository
      @require_proxy = require_proxy
    end

    # @return [Cuprum::Collections::Repository] the repository used to query
    #   middleware data.
    attr_reader :repository

    private

    attr_reader :require_proxy

    def create_middleware(class_name, attribute_name = nil, **options) # rubocop:disable Metrics/MethodLength
      step { validate_class_name(class_name, attribute_name, **options) }

      args    = attribute_name ? [attribute_name] : []
      options = options.merge(repository: repository)

      Object.const_get(class_name).new(*args, **options)
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

    def evaluate_requires(require_statements)
      require_statements.each do |require_path|
        require_proxy.require require_path
      end
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
      requires   = Array(options.delete('require'))
      middleware = options.delete('middleware')

      evaluate_requires(requires)
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
