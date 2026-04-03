# frozen_string_literal: true

module Akaitsume
  module Provider
    Response = Data.define(:content, :stop_reason, :model, :usage) do
      def initialize(content:, stop_reason:, model:, usage: {})
        super(content: content, stop_reason: stop_reason, model: model, usage: usage)
      end

      def tool_use?
        stop_reason == :tool_use
      end

      def input_tokens
        usage[:input_tokens] || 0
      end

      def output_tokens
        usage[:output_tokens] || 0
      end

      def total_tokens
        input_tokens + output_tokens
      end
    end
  end
end
