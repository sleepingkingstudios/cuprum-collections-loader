# frozen_string_literal: true

require 'cuprum/collections/loader'

module Cuprum::Collections::Loader
  # Namespace for parsing options.
  module Options
    autoload :Parse, 'cuprum/collections/loader/options/parse'
  end
end
