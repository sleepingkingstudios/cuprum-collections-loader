# frozen_string_literal: true

require 'yaml'

require 'cuprum/collections/loader/formats'

module Cuprum::Collections::Loader::Formats
  # Parses a raw YAML document and performs cleanup on multiline strings.
  class ParseYaml < Cuprum::Command
    # @param options [Hash<String, Hash>] Configuration options for the data
    #   attributes.
    def initialize(options: {})
      super()

      @options = options
    end

    # @return [Hash<String, Hash>] configuration options for the data
    #   attributes.
    attr_reader :options

    private

    def cleanup_data(data)
      data.to_h do |key, value|
        next [key, value] unless value.is_a?(String)

        value = value.strip
        value = value.gsub(/\s+/, ' ') unless multiline?(key)

        [key, value]
      end
    end

    def data_error(raw_yaml, parsed, message: nil)
      Cuprum::Collections::Loader::Errors::DataError.new(
        format:       :yaml,
        message:      message,
        parsed_value: parsed,
        raw_value:    raw_yaml
      )
    end

    def multiline?(attribute_name)
      return false if options.nil? || options.empty?

      attribute_options = options[attribute_name]

      return false unless attribute_options.is_a?(Hash)

      !!attribute_options['multiline']
    end

    def parse_error(raw_yaml, message: nil)
      Cuprum::Collections::Loader::Errors::ParseError.new(
        format:    :yaml,
        message:   message,
        raw_value: raw_yaml
      )
    end

    def parse_yaml(raw_yaml)
      YAML.safe_load(raw_yaml)
    rescue Psych::Exception => exception
      failure(parse_error(raw_yaml, message: exception.message))
    rescue TypeError
      failure(parse_error(raw_yaml))
    end

    def process(raw_yaml)
      parsed = step { parse_yaml(raw_yaml) }

      case parsed
      when Array
        return failure(data_error(raw_yaml, parsed)) unless valid_array?(parsed)

        parsed.map { |hsh| cleanup_data(hsh) }
      when Hash
        cleanup_data(parsed)
      else
        failure(data_error(raw_yaml, parsed))
      end
    end

    def valid_array?(parsed)
      parsed.all? { |item| item.is_a?(Hash) }
    end
  end
end
