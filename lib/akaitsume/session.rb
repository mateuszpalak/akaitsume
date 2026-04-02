# frozen_string_literal: true

require 'securerandom'

module Akaitsume
  class Session
    attr_reader :id, :messages, :system_prompt, :metadata

    def initialize(system_prompt: nil)
      @id            = SecureRandom.hex(8)
      @messages      = []
      @system_prompt = system_prompt
      @metadata      = { turns: 0, input_tokens: 0, output_tokens: 0 }
    end

    def add_user(content)
      @messages << { role: 'user', content: content }
    end

    def add_assistant(content)
      @messages << { role: 'assistant', content: content }
      @metadata[:turns] += 1
    end

    def add_tool_results(results)
      @messages << { role: 'user', content: results }
    end

    def track_usage(response)
      @metadata[:input_tokens]  += response.input_tokens
      @metadata[:output_tokens] += response.output_tokens
    end

    def turn_count
      @metadata[:turns]
    end

    def total_tokens
      @metadata[:input_tokens] + @metadata[:output_tokens]
    end
  end
end
