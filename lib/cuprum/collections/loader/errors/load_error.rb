# frozen_string_literal: true

require 'cuprum/collections/loader/errors'

module Cuprum::Collections::Loader::Errors
  # Error returned when unable to load a data file.
  class LoadError < Cuprum::Error
    # Short string used to identify the type of error.
    TYPE = 'librum/data/errors/load_error'

    # @param file_path [String] The path to the expected file.
    # @param message [String] The error message to display.
    def initialize(file_path:, message: nil)
      @file_path = file_path

      super(file_path: file_path, message: generate_message(message))
    end

    # @param [String] the path to the expected file.
    attr_reader :file_path

    private

    def as_json_data
      { 'file_path' => file_path }
    end

    def generate_message(message)
      if message
        "Unable to load file #{file_path}: #{message}"
      else
        "Unable to load file #{file_path}"
      end
    end
  end
end
