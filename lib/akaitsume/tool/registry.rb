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

      # Auto-discover and register all built-in Tool classes.
      # Resolves constructor args from the provided context.
      def self.default_for(config, memory: nil)
        context = { workspace: config.workspace, memory: memory }

        new.tap do |r|
          discover_tools.each do |klass|
            args = resolve_args(klass, context)
            next if args.nil? # skip if required args not available

            r.register(klass, **args)
          end

          # Load external tools from config paths
          load_external(config.tool_paths).each do |klass|
            args = resolve_args(klass, context) || {}
            r.register(klass, **args)
          end
        end
      end

      # Find all classes in Akaitsume::Tool that include Tool::Base
      def self.discover_tools
        Tool.constants
            .map { |name| Tool.const_get(name) }
            .select { |klass| klass.is_a?(Class) && klass < Base }
      end

      # Match a tool's initialize params to the available context
      def self.resolve_args(klass, context)
        params = klass.instance_method(:initialize).parameters
        return {} if params.empty?

        args = {}
        params.each do |type, name|
          if context.key?(name)
            args[name] = context[name]
          elsif %i[keyreq req].include?(type)
            return nil # required arg missing — skip this tool
          end
        end
        args
      end

      # Load .rb files from external paths, return tool classes defined in them
      def self.load_external(paths)
        return [] if paths.empty?

        before = Tool.constants.dup
        paths.each do |path|
          Dir.glob(File.join(path, '*.rb')).each { |f| require f }
        end
        new_constants = Tool.constants - before
        new_constants
          .map { |name| Tool.const_get(name) }
          .select { |klass| klass.is_a?(Class) && klass < Base }
      end

      private_class_method :discover_tools, :resolve_args, :load_external
    end
  end
end
