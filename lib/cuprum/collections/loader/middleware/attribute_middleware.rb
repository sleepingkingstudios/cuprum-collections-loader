# frozen_string_literal: true

require 'cuprum/collections/loader/middleware'

module Cuprum::Collections::Loader::Middleware
  # Middleware that acts on a specific data attribute.
  class AttributeMiddleware < Cuprum::Collections::Loader::Middleware::EntityMiddleware
    # @param attribute_name [String, Symbol] The name of the attribute.
    # @param options [Hash<Symbol, Object>] Options for the middleware.
    def initialize(attribute_name, **options)
      super(**options)

      @attribute_name = attribute_name
    end

    # @return [String, Symbol] the name of the attribute.
    attr_reader :attribute_name
  end
end
