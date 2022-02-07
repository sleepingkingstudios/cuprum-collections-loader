# frozen_string_literal: true

require 'cuprum/collections/loader/errors'

module Cuprum::Collections::Loader::Errors
  # Error returned when unable to create the configured middleware.
  class MiddlewareError < Cuprum::Error
    # Short string used to identify the type of error.
    TYPE = 'librum/data/errors/middleware_error'

    # @param attribute_name [String, Symbol] The name of the middleware
    #   attribute, if any.
    # @param middleware [String] The class name of the configured middleware.
    # @param options [Hash<String, Object>] The configured options.
    def initialize(middleware:, attribute_name: nil, options: nil, message: nil)
      @attribute_name = attribute_name
      @middleware     = middleware
      @options        = options

      super(
        attribute_name: attribute_name,
        middleware:     middleware,
        options:        options,
        message:        generate_message(message)
      )
    end

    # @return [String, Symbol] the name of the middleware attribute, if any.
    attr_reader :attribute_name

    # @return [Class] the class of the configured middleware.
    attr_reader :middleware

    # @return [Hash<String, Object>] the configured options.
    attr_reader :options

    private

    def as_json_data
      {
        'attribute_name' => attribute_name&.to_s,
        'middleware'     => middleware,
        'options'        => options.inspect
      }
    end

    def attribute_name?
      !(attribute_name.nil? || attribute_name.empty?)
    end

    def generate_message(message)
      "unable to generate middleware #{middleware}" \
        "#{attribute_name? ? " for attribute #{attribute_name.inspect}" : ''}" \
        "#{options? ? " with options #{options.inspect}" : ''}" \
        "#{message.nil? || message.empty? ? '' : ": #{message}"}"
    end

    def options?
      return false if options.nil?

      return false if options.respond_to?(:empty?) && options.empty?

      true
    end
  end
end
