# frozen_string_literal: true

require 'cuprum/collections/loader/errors'

module Cuprum::Collections::Loader::Errors
  # Error returned when trying to access a missing collection.
  class CollectionError < Cuprum::Error
    # Short string used to identify the type of error.
    TYPE = 'cuprum/collections/loader/errors/collection_error'

    # @param qualified_name [String] The qualified name of the missing
    #   collection.
    # @param repository [Cuprum::Collections::Repository] The repository which
    #   was expected to include the collection.
    def initialize(qualified_name:, repository:)
      @qualified_name = qualified_name
      @repository     = repository

      super(
        message:        generate_message,
        qualified_name: qualified_name,
        repository:     repository
      )
    end

    # @return [String] the qualified name of the missing collection.
    attr_reader :qualified_name

    # @return [Cuprum::Collections::Repository] the repository which was
    #   expected to include the collection.
    attr_reader :repository

    private

    def as_json_data
      {
        'collections'      => repository.keys,
        'qualified_name'   => qualified_name,
        'repository_class' => repository.class.name
      }
    end

    def generate_message
      "collection not found with qualified name #{qualified_name.inspect}"
    end
  end
end
