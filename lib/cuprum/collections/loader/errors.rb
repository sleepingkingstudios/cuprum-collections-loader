# frozen_string_literal: true

require 'cuprum/collections/loader'

module Cuprum::Collections::Loader
  # Namespace for error objects, which represent failure states.
  module Errors
    autoload :CollectionError,
      'cuprum/collections/loader/errors/collection_error'
    autoload :DataError,
      'cuprum/collections/loader/errors/data_error'
    autoload :LoadError,
      'cuprum/collections/loader/errors/load_error'
    autoload :MiddlewareError,
      'cuprum/collections/loader/errors/middleware_error'
    autoload :ParseError,
      'cuprum/collections/loader/errors/parse_error'
  end
end
