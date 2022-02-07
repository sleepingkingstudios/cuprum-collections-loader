# frozen_string_literal: true

require 'cuprum/collections/loader/middleware/entity_middleware'

require 'support/middleware'

module Spec::Support::Middleware
  class EncryptPassword <
        Cuprum::Collections::Loader::Middleware::EntityMiddleware
    private

    def encrypt(password)
      password
        .downcase
        .gsub(/[^a-z]+/, '')
        .each_char
        .map { |chr| rot13(chr) }
        .join
    end

    def process(next_command, attributes = {})
      attributes = attributes.dup
      password   = attributes.delete('password') || ''
      attributes = attributes.merge('encrypted_password' => encrypt(password))

      super(next_command, attributes)
    end

    def rot13(chr)
      (((chr.ord - 66) % 26) + 97).chr
    end
  end
end
