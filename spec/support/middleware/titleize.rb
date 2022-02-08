# frozen_string_literal: true

require 'cuprum/collections/loader/middleware/attribute_middleware'

require 'support/middleware'

module Spec::Support::Middleware
  class Titleize < Cuprum::Collections::Loader::Middleware::AttributeMiddleware
    private

    def process(next_command, attributes:)
      attributes = attributes.dup
      attr_value = attributes[attribute_name] || ''
      attr_value = attr_value.split.map(&:capitalize).join(' ')
      attributes = attributes.merge(attribute_name => attr_value)

      super(next_command, attributes: attributes)
    end
  end
end
