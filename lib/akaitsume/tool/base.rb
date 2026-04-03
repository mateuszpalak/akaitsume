# frozen_string_literal: true

module Akaitsume
  module Tool
    module Base
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def tool_name(name = nil)
          @tool_name = name if name
          @tool_name || raise(NotImplementedError, "#{self}.tool_name not defined")
        end

        def description(desc = nil)
          @description = desc if desc
          @description || raise(NotImplementedError, "#{self}.description not defined")
        end

        def input_schema(schema = nil)
          @input_schema = schema if schema
          @input_schema || { type: 'object', properties: {}, required: [] }
        end

        # Returns the tool definition hash for Anthropic API
        def to_api_definition
          {
            name: tool_name,
            description: description,
            input_schema: input_schema
          }
        end
      end

      # Instance method — override in each tool
      def call(input)
        raise NotImplementedError, "#{self.class}#call not implemented"
      end

      # Normalizes input keys to strings and wraps result into Anthropic tool_result content format
      def execute(input)
        normalized = input.is_a?(Hash) ? input.transform_keys(&:to_s) : input
        result = call(normalized)
        { type: 'text', text: result.to_s }
      rescue StandardError => e
        { type: 'text', text: "Error: #{e.message}" }
      end
    end
  end
end
