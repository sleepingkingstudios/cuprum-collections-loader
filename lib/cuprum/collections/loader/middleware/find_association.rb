# frozen_string_literal: true

require 'cuprum/collections/commands/find_one_matching'

require 'cuprum/collections/loader/middleware'
require 'cuprum/collections/loader/middleware/attribute_middleware'

module Cuprum::Collections::Loader::Middleware
  # Finds the given assocation using the configured repository.
  class FindAssociation <
        Cuprum::Collections::Loader::Middleware::AttributeMiddleware
    # @param attribute_name [String, Symbol] The name of the attribute.
    # @param find_by [String] The attribute used to find the association.
    #   Defaults to 'id'.
    # @param optional [true, false] If false, the command will fail if the
    #   association is not found. Defaults to false.
    # @param options [Hash<Symbol, Object>] Options for the middleware.
    # @param qualified_name [String] The qualified name of the collection to
    #   query. Defaults to the pluralized attribute name.
    # @param repository [Cuprum::Collections::Repository] The repository used
    #   to query data.
    def initialize( # rubocop:disable Metrics/ParameterLists
      attribute_name,
      repository:,
      find_by:        'id',
      optional:       false,
      qualified_name: nil,
      **options
    )
      super

      @find_by        = find_by
      @optional       = optional
      @qualified_name =
        qualified_name || tools.string_tools.pluralize(attribute_name)
    end

    # @return [String, Array<String>] the attribute used to find the
    #   association.
    attr_reader :find_by

    # @return [String] he qualified name of the collection to query.
    attr_reader :qualified_name

    # @return [true, false] if false, the command will fail if the association
    #   is not found.
    def optional?
      @optional
    end

    private

    def collection_error
      Cuprum::Collections::Loader::Errors::CollectionError.new(
        qualified_name: qualified_name,
        repository:     repository
      )
    end

    def find_association(attr_value)
      collection = step { find_collection }
      result     =
        Cuprum::Collections::Commands::FindOneMatching
        .new(collection: collection)
        .call(attributes: { find_by => attr_value })

      return result unless result.failure? && optional?

      success(nil)
    end

    def find_collection
      return @collection if @collection

      if repository.key?(qualified_name)
        return @collection = repository[qualified_name]
      end

      failure(collection_error)
    end

    def process(next_command, attributes:)
      attr_value  = attributes[attribute_name]
      association = step { find_association(attr_value) }
      attributes  = attributes.merge(attribute_name => association)

      super(next_command, attributes: attributes)
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end
  end
end
