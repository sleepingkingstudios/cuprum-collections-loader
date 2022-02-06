# frozen_string_literal: true

require 'cuprum/collections/loader'

module Cuprum::Collections::Loader
  # Namespace for format-specific data parsers.
  module Formats
    autoload :ParseYaml, 'cuprum/collections/loader/formats/parse_yaml'
  end
end
