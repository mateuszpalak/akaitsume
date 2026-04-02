# frozen_string_literal: true

module Akaitsume
  module Tool
    class MemoryTool
      include Base

      tool_name   'memory'
      description 'Read, store, and search your long-term memory. ' \
                  "Use 'store' to remember important facts. " \
                  "Use 'read' to recall everything. " \
                  "Use 'search' to find specific information."

      input_schema({
                     type: 'object',
                     properties: {
                       action: {
                         type: 'string',
                         enum: %w[read store search replace],
                         description: 'Memory operation to perform'
                       },
                       content: {
                         type: 'string',
                         description: 'Content to store or replace (required for store/replace)'
                       },
                       query: {
                         type: 'string',
                         description: 'Search query (required for search)'
                       }
                     },
                     required: %w[action]
                   })

      def initialize(memory:)
        @memory = memory
      end

      def call(input)
        action = input['action'] || input[:action]

        case action
        when 'read'
          @memory.read || '(empty memory)'
        when 'store'
          content = input['content'] || input[:content]
          return 'Error: content is required for store' unless content

          @memory.store(content)
          'Stored to memory.'
        when 'search'
          query = input['query'] || input[:query]
          return 'Error: query is required for search' unless query

          @memory.search(query)
        when 'replace'
          content = input['content'] || input[:content]
          return 'Error: content is required for replace' unless content

          @memory.replace(content)
          'Memory replaced.'
        else
          "Error: unknown action '#{action}'"
        end
      end
    end
  end
end
