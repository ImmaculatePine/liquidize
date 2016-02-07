require 'liquid'

module Liquidize
  module Model

    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods

      # Adds Liquid support to the following attribute
      # @param attribute [String, Symbol] attribute to be liquidized
      def liquidize(attribute)
        define_liquid_template_method(attribute)
        define_parse_liquid_method(attribute)
        define_render_method(attribute)
        override_setter(attribute)
        if defined?(ActiveRecord) && self.ancestors.include?(ActiveRecord::Base)
          define_validator(attribute)
          validate "validate_#{attribute}_liquid_syntax"
        end
      end

      private

        def define_parse_liquid_method(attribute)
          define_method "parse_liquid_#{attribute}!" do
            begin
              original_value = public_send(attribute)
              parsed_value = Liquid::Template.parse(original_value)
              instance_variable_set("@liquid_#{attribute}_template", parsed_value)
              if activerecord? && respond_to?("liquid_#{attribute}")
                send("liquid_#{attribute}=", Base64.strict_encode64(Marshal.dump(parsed_value)))
              end
            rescue Liquid::SyntaxError => error
              instance_variable_set("@#{attribute}_syntax_error", error.message)
            end
          end
        end

        def define_liquid_template_method(attribute)
          define_method "liquid_#{attribute}_template" do
            result = instance_variable_get("@liquid_#{attribute}_template")
            return result unless result.nil?

            if respond_to?("liquid_#{attribute}") && send("liquid_#{attribute}").present?
              dump = send("liquid_#{attribute}")
              decoded_template = Marshal.load(Base64.strict_decode64(dump))
              instance_variable_set("@liquid_#{attribute}_template", decoded_template)
            else
              send("parse_#{attribute}_template!")
              save if activerecord?
            end

            instance_variable_get("@liquid_#{attribute}_template")
          end
        end

        def define_render_method(attribute)
          define_method "render_#{attribute}" do |options = {}|
            send("liquid_#{attribute}_template").render(Liquidize::Helper.recursive_stringify_keys(options))
          end
        end

        def define_validator(attribute)
          define_method("validate_#{attribute}_liquid_syntax") do
            syntax_error = instance_variable_get("@#{attribute}_syntax_error")
            errors.add(attribute, syntax_error) if syntax_error.present?
          end
        end

        def override_setter(attribute)
          # Undefine old method to prevent warning
          undef_method "#{attribute}=".to_sym if method_defined? "#{attribute}="

          # Define new method
          define_method "#{attribute}=" do |value|
            # Set *_syntax_error instance variable to nil because:
            #   * old value could be invalid, but the new one is valid
            #   * it prevents warning
            instance_variable_set("@#{attribute}_syntax_error", nil)
            if activerecord?
              write_attribute(attribute, value)
            else
              instance_variable_set("@#{attribute}", value)
            end
            send("parse_liquid_#{attribute}!")
            value
          end
        end
    end

    private

      def activerecord?
        defined?(ActiveRecord) && self.class.ancestors.include?(ActiveRecord::Base)
      end

  end
end