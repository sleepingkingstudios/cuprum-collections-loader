# frozen_string_literal: true

require 'cuprum'

require 'cuprum/collections/loader/middleware'

module Cuprum::Collections::Loader::Middleware
  # Abstract base command for data middleware.
  class EntityMiddleware < Cuprum::Command
    include Cuprum::Middleware

    # @param options [Hash<Symbol, Object>] Options for the middleware.
    # @param repository [Cuprum::Collections::Repository] The repository used
    #   to query data.
    def initialize(repository: nil, **options)
      super()

      @options    = options.merge(repository: repository)
      @repository = repository
    end

    # @return [Hash<Symbol, Object>] options for the middleware.
    attr_reader :options

    # @return [Cuprum::Collections::Repository] the repository used to query
    #   data.
    attr_reader :repository
  end
end
