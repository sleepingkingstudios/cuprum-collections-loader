# frozen_string_literal: true

require 'cuprum/collections/commands/upsert'

require 'cuprum/collections/loader'
require 'cuprum/collections/loader/options/parse'
require 'cuprum/collections/loader/read'

module Cuprum::Collections::Loader
  # Reads data and options and creates data entities from configuration files.
  class Load < Cuprum::Command
    # @param data_path [String] The root url of the data files.
    def initialize(data_path:)
      super(&nil)

      @data_path = data_path
    end

    # @return [String] the root url of the data files.
    attr_reader :data_path

    private

    def apply_middleware(collection:, options:)
      command    = Cuprum::Collections::Commands::Upsert.new(
        attribute_names: options.fetch('find_by', 'id'),
        collection:      collection
      )
      middleware = options.fetch('middleware', [])

      Cuprum::Middleware.apply(command: command, middleware: middleware)
    end

    def parse_options(options)
      Cuprum::Collections::Loader::Options::Parse.new.call(options: options)
    end

    def process(collection:, relative_path: nil)
      relative_path ||= collection.collection_name
      data, options  = step { read_data(relative_path: relative_path) }
      parsed_options = step { parse_options(options) }

      upsert_entities(
        collection: collection,
        data:       data,
        options:    parsed_options
      )
    end

    def read_data(relative_path:)
      Cuprum::Collections::Loader::Read
        .new(data_path: data_path)
        .call(relative_path: relative_path)
    end

    def upsert_entities(collection:, data:, options:)
      upsert_command =
        apply_middleware(collection: collection, options: options)

      results = data.map do |attributes|
        upsert_command.call(attributes: attributes)
      end

      Cuprum::ResultList.new(*results)
    end
  end
end
