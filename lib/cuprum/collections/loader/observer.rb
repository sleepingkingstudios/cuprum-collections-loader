# frozen_string_literal: true

require 'cuprum/collections/loader'

module Cuprum::Collections::Loader
  # Default Observer for monitoring data loading.
  class Observer
    def update(action, details)
      send(action, **details)
    end

    private

    def attributes_message(attributes:, options:, result:)
      attr_names = Array(options.fetch('find_by', 'id'))
      filters    = attr_names.map do |attr_name|
        _, entity = result.value

        [
          attr_name,
          ((entity && entity[attr_name]) || attributes[attr_name]).inspect
        ]
      end

      "with #{filters.map { |pair| pair.join(' ') }.join(', ')}"
    end

    def error(collection_name:, error:, relative_path:)
      message = "[Error] An error occurred when loading #{collection_name}"

      unless collection_name == relative_path
        message = "#{message} (#{relative_path})"
      end

      puts "#{message}: #{error.message}"
    end

    def failure(attributes:, collection_name:, options:, result:) # rubocop:disable Metrics/MethodLength
      collection_name = tools.string_tools.singularize(collection_name)
      action          =
        result.value.is_a?(Array) ? result.value.first : 'process'
      message         = "Unable to #{action} #{collection_name}"
      with_message    =
        attributes_message(
          attributes: attributes,
          options:    options,
          result:     result
        )

      puts "- #{message} #{with_message}: #{result.error.message}"
    end

    def finish(**_); end

    def start(collection_name:, data:, data_path:, relative_path:, **_)
      if data.count == 1
        collection_name = tools.string_tools.singularize(collection_name)
      end

      message = "Loading #{data.count} #{collection_name}"
      message = "#{message} from #{File.join(data_path, relative_path)}"

      puts message
    end

    def success(attributes:, collection_name:, options:, result:)
      collection_name = tools.string_tools.singularize(collection_name)
      action          = result.value.first
      message         = "Successfully #{action}d #{collection_name}"
      with_message    =
        attributes_message(
          attributes: attributes,
          options:    options,
          result:     result
        )

      puts "- #{message} #{with_message}"
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end
  end
end
