# frozen_string_literal: true

module Akaitsume
  module Provider
    module Base
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def provider_name(name = nil)
          @provider_name = name if name
          @provider_name || self.name
        end
      end

      # Send messages to the LLM and return a Provider::Response.
      # Must be implemented by each provider.
      def chat(messages:, system:, tools:, model:, max_tokens:)
        raise NotImplementedError, "#{self.class}#chat not implemented"
      end
    end
  end
end
