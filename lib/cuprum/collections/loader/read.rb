# frozen_string_literal: true

require 'cuprum/collections/loader'

module Cuprum::Collections::Loader
  # Reads and parses data and options from configuration files.
  class Read < Cuprum::Command # rubocop:disable Metrics/ClassLength
    # @overload initialize(data_path:)
    #   @param data_path [String] The root url of the data files.
    def initialize(data_path:, dir_proxy: Dir, file_proxy: File)
      super()

      @data_path  = data_path
      @dir_proxy  = dir_proxy
      @file_proxy = file_proxy
    end

    # @return [String] the root url of the data files.
    attr_reader :data_path

    private

    attr_reader :dir_proxy

    attr_reader :file_proxy

    def data_dir_exists?(qualified_path)
      dir_exists?(qualified_path)
    end

    def data_error(raw_yaml, parsed, message: nil)
      Cuprum::Collections::Loader::Errors::DataError.new(
        format:       :yaml,
        message:      message,
        parsed_value: parsed,
        raw_value:    raw_yaml
      )
    end

    def dir_exists?(dir_path)
      file_proxy.exist?(dir_path) && file_proxy.directory?(dir_path)
    end

    def data_file_exists?(qualified_path)
      file_exists?("#{qualified_path}.yml")
    end

    def each_data_file(qualified_path, &block)
      dir_proxy
        .glob(File.join(qualified_path, '*.yml'))
        .reject { |file_path| File.basename(file_path).start_with?('_') }
        .each(&block)
    end

    def file_exists?(file_path)
      file_proxy.exist?(file_path) && file_proxy.file?(file_path)
    end

    def load_data_dir(qualified_path)
      data    = []
      options = step { load_options("#{qualified_path}/_options.yml") }
      parser  =
        Cuprum::Collections::Loader::Formats::ParseYaml.new(options: options)

      each_data_file(qualified_path) do |file_path|
        raw_data = file_proxy.read(file_path)

        data << step { parser.call(raw_data) }
      end

      [data, options]
    end

    def load_data_file(qualified_path)
      options  = step { load_options("#{qualified_path}_options.yml") }
      raw_data = file_proxy.read("#{qualified_path}.yml")
      parser   =
        Cuprum::Collections::Loader::Formats::ParseYaml.new(options: options)
      data     = step { parser.call(raw_data) }

      [data, options]
    end

    def load_options(options_path)
      global_path    = File.join(data_path, '_options.yml')
      global_options = step { load_options_file(global_path) }
      local_options  = step { load_options_file(options_path) }

      global_options.merge(local_options)
    end

    def load_options_file(options_path) # rubocop:disable Metrics/MethodLength
      return {} unless file_exists?(options_path)

      raw_options    = file_proxy.read(options_path)
      parsed_options = YAML.safe_load(raw_options)

      return success(parsed_options) if parsed_options.is_a?(Hash)

      failure(
        data_error(
          raw_options, parsed_options, message: 'options must be a Hash'
        )
      )
    rescue Psych::Exception => exception
      failure(parse_error(raw_options, message: exception.message))
    end

    def load_error(file_path:, message: nil)
      Cuprum::Collections::Loader::Errors::LoadError
        .new(file_path: file_path, message: message)
    end

    def not_found_error(qualified_path)
      load_error(
        file_path: qualified_path,
        message:   'no such file or directory'
      )
    end

    def parse_error(raw_yaml, message: nil)
      Cuprum::Collections::Loader::Errors::ParseError.new(
        format:    :yaml,
        message:   message,
        raw_value: raw_yaml
      )
    end

    def process(relative_path:)
      qualified_path = File.join(data_path, relative_path)

      if data_dir_exists?(qualified_path)
        load_data_dir(qualified_path)
      elsif data_file_exists?(qualified_path)
        load_data_file(qualified_path)
      else
        failure(not_found_error(qualified_path))
      end
    end
  end
end
