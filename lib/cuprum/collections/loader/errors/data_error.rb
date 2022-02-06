# frozen_string_literal: true

require 'cuprum/collections/loader/errors'

module Cuprum::Collections::Loader::Errors
  # Error returned when parsing data returns an invalid value.
  class DataError < Cuprum::Error
    # Short string used to identify the type of error.
    TYPE = 'librum/data/errors/data_error'

    # @param format [String] The expected format of the value.
    # @param parsed_value [Object] The parsed value.
    # @param raw_value [Object] The raw value prior to parsing.
    # @param message [String] The error message to display.
    def initialize(format:, parsed_value:, raw_value:, message: nil)
      @format       = format
      @parsed_value = parsed_value
      @raw_value    = raw_value

      super(
        format:       format,
        parsed_value: parsed_value,
        raw_value:    raw_value,
        message:      message || default_message
      )
    end

    # @return [String] the expected format of the value.
    attr_reader :format

    # @return [Object] the parsed value.
    attr_reader :parsed_value

    # @return [Object] the raw value prior to parsing.
    attr_reader :raw_value

    private

    def as_json_data
      {
        'format'       => format.to_s,
        'parsed_value' => parsed_value.inspect,
        'raw_value'    => raw_value.inspect
      }
    end

    def default_message
      "Invalid #{format} data object:\n\n  raw_value:\n" \
        "#{tools.string_tools.indent(raw_value.inspect, 4)}" \
        "\n\n  parsed value:\n" \
        "#{tools.string_tools.indent(parsed_value.inspect, 4)}"
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end
  end
end
