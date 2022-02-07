# frozen_string_literal: true

require 'cuprum'

require 'cuprum/collections/loader/middleware'

module Cuprum::Collections::Loader::Middleware
  # Abstract base command for data middleware.
  class EntityMiddleware < Cuprum::Command
    include Cuprum::Middleware

    # @param options [Hash<Symbol, Object>] Options for the middleware.
    def initialize(**options)
      super()

      @options = options
    end

    # @return [Hash<Symbol, Object>] options for the middleware.
    attr_reader :options
  end
end
