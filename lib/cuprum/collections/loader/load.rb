# frozen_string_literal: true

require 'observer'

require 'cuprum/collections/loader'
require 'cuprum/collections/loader/options/parse'
require 'cuprum/collections/loader/read'
require 'cuprum/collections/loader/upsert'

module Cuprum::Collections::Loader
  # Reads data and options and creates data entities from configuration files.
  class Load < Cuprum::Command # rubocop:disable Metrics/ClassLength
    include Observable

    # @param data_path [String] The root url of the data files.
    # @param repository [Cuprum::Collections::Repository] The repository used to
    #   query middleware data.
    def initialize(data_path:, repository: nil)
      super(&nil)

      @data_path  = data_path
      @repository = repository
    end

    # @return [String] the root url of the data files.
    attr_reader :data_path

    # @return [Cuprum::Collections::Repository] the repository used to query
    #   middleware data.
    attr_reader :repository

    private

    def apply_middleware(collection:, options:)
      command = Cuprum::Collections::Loader::Upsert.new(
        attribute_names: options.fetch('find_by', 'id'),
        collection:      collection
      )
      middleware = options.fetch('middleware', [])

      Cuprum::Middleware.apply(command: command, middleware: middleware)
    end

    def notify(action, **options)
      changed

      notify_observers(action, options)
    end

    def notify_process(collection:, **options)
      notify_process_start(collection: collection, **options)

      results = yield

      notify_process_finish(collection: collection, results: results)

      results
    end

    def notify_process_finish(collection:, results:)
      notify(
        :finish,
        collection_name: collection.collection_name,
        results:         results
      )
    end

    def notify_process_start(collection:, data:, options:, relative_path:)
      notify(
        :start,
        collection_name: collection.collection_name,
        data:            data,
        data_path:       data_path,
        options:         options,
        relative_path:   relative_path
      )
    end

    def notify_read(collection:, relative_path:, &block) # rubocop:disable Metrics/MethodLength
      step do
        result = steps(&block)

        next result if result.success?

        notify(
          :error,
          collection_name: collection.collection_name,
          error:           result.error,
          relative_path:   relative_path
        )

        result
      end
    end

    def notify_result(attributes:, collection:, options:)
      result = yield

      notify(
        result.status,
        attributes:      attributes,
        collection_name: collection.collection_name,
        options:         options,
        result:          result
      )

      result
    end

    def parse_options(options)
      Cuprum::Collections::Loader::Options::Parse
        .new(repository: repository)
        .call(options: options)
    end

    def process(collection:, relative_path: nil) # rubocop:disable Metrics/MethodLength
      relative_path ||= collection.collection_name
      data, options, parsed_options = nil

      notify_read(collection: collection, relative_path: relative_path) do
        data, options  = step { read_data(relative_path: relative_path) }
        parsed_options = step { parse_options(options) }
      end

      notify_process(
        collection:    collection,
        data:          data,
        options:       options,
        relative_path: relative_path
      ) \
      do
        upsert_entities(
          collection: collection,
          data:       data,
          options:    parsed_options
        )
      end
    end

    def read_data(relative_path:)
      Cuprum::Collections::Loader::Read
        .new(data_path: data_path)
        .call(relative_path: relative_path)
    end

    def upsert_entities(collection:, data:, options:) # rubocop:disable Metrics/MethodLength
      upsert_command =
        apply_middleware(collection: collection, options: options)

      results = data.map do |attributes|
        notify_result(
          attributes: attributes,
          collection: collection,
          options:    options
        ) \
        do
          upsert_command.call(attributes: attributes)
        end
      end

      Cuprum::ResultList.new(*results)
    end
  end
end
