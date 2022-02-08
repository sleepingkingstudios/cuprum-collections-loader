# frozen_string_literal: true

require 'cuprum/collections/commands/upsert'

require 'cuprum/collections/loader'

module Cuprum::Collections::Loader
  # Command for creating or updating an entity from an attributes Hash.
  class Upsert < Cuprum::Collections::Commands::Upsert
    private

    def create_entity(attributes:)
      result = super

      Cuprum::Result.new(
        error:  result.error,
        status: result.status,
        value:  ['create', result.value]
      )
    end

    def find_entity(attributes:)
      result = super

      return result if result.nil? || result.success?

      Cuprum::Result.new(
        error:  result.error,
        status: result.status,
        value:  ['create or update', result.value]
      )
    end

    def update_entity(attributes:, entity:)
      result = super

      Cuprum::Result.new(
        error:  result.error,
        status: result.status,
        value:  ['update', result.value]
      )
    end
  end
end
