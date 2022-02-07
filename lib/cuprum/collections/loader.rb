# frozen_string_literal: true

require 'cuprum/collections'

module Cuprum::Collections
  # Library for loading serialized data with configured options.
  module Loader
    autoload :Errors,     'cuprum/collections/loader/errors'
    autoload :Formats,    'cuprum/collections/loader/formats'
    autoload :Middleware, 'cuprum/collections/loader/middleware'
    autoload :Read,       'cuprum/collections/loader/read'

    # @return [String] The current version of the gem.
    def self.version
      VERSION
    end
  end
end
