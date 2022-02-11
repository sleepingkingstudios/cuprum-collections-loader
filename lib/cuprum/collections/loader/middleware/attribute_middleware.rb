# frozen_string_literal: true

require 'cuprum/collections/loader/middleware'

module Cuprum::Collections::Loader::Middleware
  # Middleware that acts on a specific data attribute.
  class AttributeMiddleware <
        Cuprum::Collections::Loader::Middleware::EntityMiddleware
    # @param attribute_name [String, Symbol] The name of the attribute.
    # @param options [Hash<Symbol, Object>] Options for the middleware.
    # @param repository [Cuprum::Collections::Repository] The repository used
    #   to query data.
    def initialize(attribute_name, repository: nil, **options)
      super(repository: repository, **options)

      validate_attribute_name!(attribute_name)

      @attribute_name = attribute_name
    end

    # @return [String, Symbol] the name of the attribute.
    attr_reader :attribute_name

    private

    def validate_attribute_name!(attribute_name)
      return if attribute_name.is_a?(String) && !attribute_name.empty?

      if attribute_name.is_a?(Hash) && options == { repository: nil }
        raise ArgumentError, 'wrong number of arguments (given 0, expected 1)'
      end

      raise ArgumentError, "invalid attribute name #{attribute_name.inspect}"
    end
  end
end
