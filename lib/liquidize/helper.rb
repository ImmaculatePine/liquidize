module Liquidize
  module Helper
    # Converts all keys to strings
    # @params options [Hash] hash which keys should be stringified
    # @return [Hash] the same hash with stringified keys
    def self.recursive_stringify_keys(options)
      if options.is_a?(Hash)
        options.stringify_keys!
        options.each { |k, v| recursive_stringify_keys(v) }
      end
      options
    end
  end
end