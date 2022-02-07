# frozen_string_literal: true

require 'cuprum/collections/loader'

module Cuprum::Collections::Loader
  # Namespace for middleware, which wraps creating or updating entities.
  module Middleware
    autoload :EntityMiddleware,
      'cuprum/collections/loader/middleware/entity_middleware'
  end
end
