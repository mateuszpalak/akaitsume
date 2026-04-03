# frozen_string_literal: true

require 'thor'

module Akaitsume
  class CLI < Thor
    class_option :config, type: :string, desc: 'Path to config YAML file'

    desc 'run PROMPT', 'Run agent with a single prompt'
    method_option :model, type: :string, desc: 'Override model name'
    def run_task(prompt)
      agent = build_agent
      agent.before_tool { |name, input| say "  \u2192 [#{name}] #{input.inspect}", :cyan }
      agent.after_tool  { |name, _result| say "  \u2190 [#{name}]", :cyan }

      say "\n\xF0\x9F\x94\xB4 akaitsume\n\n"
      result = agent.run(prompt)
      say result
    end
    map 'run' => :run_task

    desc 'chat', 'Interactive chat mode'
    def chat
      agent   = build_agent
      session = Session.new

      agent.before_tool { |name, _input| $stdout.print "  \u2192 [#{name}] " }
      agent.after_tool  { |name, _result| $stdout.puts "\u2190 [#{name}]" }

      say "\xF0\x9F\x94\xB4 akaitsume chat (Ctrl+C or 'exit' to quit)\n\n"

      loop do
        print '> '
        input = $stdin.gets&.chomp
        break if input.nil? || input == 'exit'
        next  if input.empty?

        result = agent.run(input, session: session)
        say "\n#{result}\n\n"
      end

      say "\nSession: #{session.turn_count} turns, #{session.total_tokens} tokens"
    rescue Interrupt
      say "\n\nSession: #{session.turn_count} turns, #{session.total_tokens} tokens"
    end

    desc 'tools', 'List registered tools'
    def tools
      cfg      = load_config
      memory   = Memory.build(cfg)
      registry = Tool::Registry.default_for(cfg, memory: memory)

      registry.names.each { |n| say "  \u2022 #{n}" }
    end

    desc 'memory SUBCOMMAND', 'Memory operations'
    subcommand 'memory', Class.new(Thor) {
      namespace 'memory'

      desc 'show [AGENT]', 'Show agent memory'
      def show(agent_name = 'akaitsume')
        cfg   = parent_load_config
        store = Memory.build(cfg, agent_name: agent_name)
        say store.read || '(empty)'
      end

      desc 'search QUERY [AGENT]', 'Search agent memory'
      def search(query, agent_name = 'akaitsume')
        cfg   = parent_load_config
        store = Memory.build(cfg, agent_name: agent_name)
        say store.search(query)
      end

      no_commands do
        def parent_load_config
          path = parent_options[:config]
          path ? Config.load(path: path) : Config.load
        end
      end
    }

    no_commands do
      def load_config
        path = options[:config]
        cfg_hash = {}
        cfg_hash[:model] = options[:model] if options[:model]

        if path
          Config.load(path: path)
        else
          Config.new(cfg_hash)
        end
      end

      def build_agent
        cfg = load_config
        Agent.new(config: cfg)
      end
    end
  end
end
