module Liquidize
  module Helper
    # Converts all keys to strings
    # @params options [Hash] hash which keys should be stringified
    # @return [Hash] the same hash with stringified keys
    def self.recursive_stringify_keys(options)
      if options.is_a?(Hash)
        options.stringify_keys!
        options.each { |_k, v| recursive_stringify_keys(v) }
      elsif options.is_a?(Array)
        options.map! { |a| recursive_stringify_keys(a) }
      end
      options
    end

    # Encodes Ruby object into marshalled dump
    # @param value [Object] Ruby object
    # @return [String] encoded dump
    def self.encode(value)
      Base64.strict_encode64(Marshal.dump(value))
    end

    # Decodes dump into the Ruby object
    # @param dump [String] encoded dump
    # @return [Object] decoded object
    def self.decode(dump)
      Marshal.load(Base64.strict_decode64(dump))
    end

    # Analogue of the ActiveSupport #present? method
    # @param value [Object] value that should be checked
    # @return [Boolean] whether value is present
    def self.present?(value)
      !value.to_s.strip.empty?
    end

    # Checks if the object is an ActiveRecord class or instance
    # @param object [Object] any object
    # @return [Boolean] whether it is AR class or instance
    def self.activerecord?(object)
      return false unless defined?(ActiveRecord)
      if object.is_a?(Class)
        object.ancestors.include?(ActiveRecord::Base)
      else
        object.class.ancestors.include?(ActiveRecord::Base)
      end
    end
  end
end
