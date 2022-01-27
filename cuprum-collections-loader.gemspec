# frozen_string_literal: true

$LOAD_PATH << './lib'

require 'cuprum/collections/loader/version'

Gem::Specification.new do |gem|
  gem.name        = 'cuprum-collections-loader'
  gem.version     = Cuprum::Collections::Loader::VERSION
  gem.summary     = 'A data loading tool that leverages Cuprum::Collections.'
  gem.description = <<~DESCRIPTION.gsub(/\s+/, ' ').strip
    Library for loading serialized data with configured options.
  DESCRIPTION
  gem.authors     = ['Rob "Merlin" Smith']
  gem.email       = ['merlin@sleepingkingstudios.com']
  gem.homepage    = 'http://sleepingkingstudios.com'
  gem.license     = 'MIT'

  gem.metadata = {
    'bug_tracker_uri'       => 'https://github.com/sleepingkingstudios/cuprum-collections-loader/issues',
    'source_code_uri'       => 'https://github.com/sleepingkingstudios/cuprum-collections-loader',
    'rubygems_mfa_required' => 'true'
  }

  gem.require_path = 'lib'
  gem.files        = Dir['lib/**/*.rb', 'LICENSE', '*.md']

  gem.required_ruby_version = '>= 2.7.0'

  gem.add_runtime_dependency 'cuprum-collections', '~> 0.2'

  gem.add_development_dependency 'rspec', '~> 3.10'
  gem.add_development_dependency 'rspec-sleeping_king_studios', '~> 2.7'
  gem.add_development_dependency 'rubocop', '~> 1.25'
  gem.add_development_dependency 'rubocop-rspec', '~> 2.8'
  gem.add_development_dependency 'simplecov', '~> 0.21'
end
