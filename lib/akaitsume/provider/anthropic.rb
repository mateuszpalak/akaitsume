# frozen_string_literal: true

module Akaitsume
  module Provider
    class Anthropic
      include Base

      provider_name "anthropic"

      def initialize(api_key:)
        @client = ::Anthropic::Client.new(api_key: api_key)
      end

      def chat(messages:, system:, tools:, model:, max_tokens:)
        raw = @client.messages(
          model:      model,
          max_tokens: max_tokens,
          system:     system,
          tools:      tools,
          messages:   messages
        )

        Response.new(
          content:     raw.content,
          stop_reason: raw.stop_reason,
          model:       raw.model,
          usage: {
            input_tokens:  raw.usage.input_tokens,
            output_tokens: raw.usage.output_tokens
          }
        )
      end
    end
  end
end
