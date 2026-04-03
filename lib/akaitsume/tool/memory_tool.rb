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
        case input['action']
        when 'read'
          @memory.read || '(empty memory)'
        when 'store'
          return 'Error: content is required for store' unless input['content']

          @memory.store(input['content'])
          'Stored to memory.'
        when 'search'
          return 'Error: query is required for search' unless input['query']

          @memory.search(input['query'])
        when 'replace'
          return 'Error: content is required for replace' unless input['content']

          @memory.replace(input['content'])
          'Memory replaced.'
        else
          "Error: unknown action '#{input['action']}'"
        end
      end
    end
  end
end
