# frozen_string_literal: true

require 'cuprum/collections/loader/errors'

module Cuprum::Collections::Loader::Errors
  # Error returned when attempting to parse an invalid value.
  class ParseError < Cuprum::Error
    # Short string used to identify the type of error.
    TYPE = 'librum/data/errors/parse_error'

    # @param format [String] The expected format of the value.
    # @param raw_value [Object] The raw value prior to parsing.
    # @param message [String] The error message to display.
    def initialize(format:, raw_value:, message: nil)
      @format    = format
      @raw_value = raw_value

      super(
        format:    format,
        raw_value: raw_value,
        message:   message || default_message
      )
    end

    # @return [String] the expected format of the value.
    attr_reader :format

    # @return [Object] the raw value prior to parsing.
    attr_reader :raw_value

    private

    def as_json_data
      {
        'format'    => format.to_s,
        'raw_value' => raw_value.inspect
      }
    end

    def default_message
      "Unable to parse object as #{format}: #{raw_value.inspect}"
    end
  end
end
