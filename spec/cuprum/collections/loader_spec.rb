# frozen_string_literal: true

require 'cuprum/collections/loader'
require 'cuprum/collections/loader/version'

RSpec.describe Cuprum::Collections::Loader do
  describe '::VERSION' do
    include_examples 'should define constant',
      :VERSION,
      -> { Cuprum::Collections::Loader::Version.to_gem_version }
  end

  describe '.version' do
    include_examples 'should define class reader',
      :version,
      described_class::VERSION
  end
end
