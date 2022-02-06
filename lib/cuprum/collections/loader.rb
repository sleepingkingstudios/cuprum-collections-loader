# frozen_string_literal: true

require 'cuprum/collections'

module Cuprum::Collections
  # Library for loading serialized data with configured options.
  module Loader
    autoload :Errors,  'cuprum/collections/loader/errors'
    autoload :Formats, 'cuprum/collections/loader/formats'

    # @return [String] The current version of the gem.
    def self.version
      VERSION
    end
  end
end
