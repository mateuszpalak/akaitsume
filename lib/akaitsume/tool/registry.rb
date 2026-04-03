# frozen_string_literal: true

module Akaitsume
  module Tool
    class Registry
      def initialize
        @tools = {}
      end

      def register(tool_class, **init_args)
        name = tool_class.tool_name
        @tools[name] = { klass: tool_class, init_args: init_args }
        self
      end

      def [](name)
        entry = @tools[name] || raise(ToolNotFoundError, "Tool '#{name}' not registered")
        entry[:instance] ||= entry[:klass].new(**entry[:init_args])
      end

      def api_definitions
        @tools.values.map { |e| e[:klass].to_api_definition }
      end

      def names
        @tools.keys
      end

      # Default registry with all built-in tools.
      # Pass memory: to enable the MemoryTool.
      def self.default_for(config, memory: nil)
        new.tap do |r|
          r.register(Akaitsume::Tool::Bash,  workspace: config.workspace)
          r.register(Akaitsume::Tool::Files, workspace: config.workspace)
          r.register(Akaitsume::Tool::Http)
          r.register(Akaitsume::Tool::MemoryTool, memory: memory) if memory
        end
      end
    end
  end
end
