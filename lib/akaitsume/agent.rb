# frozen_string_literal: true

module Akaitsume
  class Agent
    attr_reader :name, :role, :config

    def initialize(name: "akaitsume", role: :orchestrator, config: Config.load, provider: nil, tools: nil, memory: nil)
      @name     = name
      @role     = role
      @config   = config
      @provider = provider || Provider::Anthropic.new(api_key: config.api_key)
      @memory   = memory || Memory::FileStore.new(dir: config.memory_dir, agent_name: name)
      @tools    = tools || Tool::Registry.default_for(config)
      @hooks    = { before_tool: [], after_tool: [], on_response: [] }
    end

    # Spawn a sub-agent with its own tools and memory
    def spawn(name:, role:, tools: nil)
      self.class.new(
        name:     name,
        role:     role,
        config:   @config,
        provider: @provider,
        tools:    tools,
        memory:   Memory::FileStore.new(dir: @config.memory_dir, agent_name: name)
      )
    end

    # Register hooks
    def before_tool(&block) = @hooks[:before_tool] << block
    def after_tool(&block)  = @hooks[:after_tool] << block
    def on_response(&block) = @hooks[:on_response] << block

    # Run the agent loop.
    # Yields final text response if block given, returns it otherwise.
    def run(prompt, system: nil, &block)
      messages = build_initial_messages(prompt)
      sys      = system || default_system_prompt
      turns    = 0

      loop do
        raise MaxTurnsError, "Exceeded max_turns (#{@config.max_turns})" if turns >= @config.max_turns
        turns += 1

        response = @provider.chat(
          model:      @config.model,
          max_tokens: @config.max_tokens,
          system:     sys,
          tools:      @tools.api_definitions,
          messages:   messages
        )

        # Append assistant message
        messages << { role: "assistant", content: response.content }

        if response.tool_use?
          tool_results = dispatch_tools(response.content)
          messages << { role: "user", content: tool_results }
        else
          text = extract_text(response.content)
          @hooks[:on_response].each { |h| h.call(text) }
          block ? block.call(text) : (return text)
          return text
        end
      end
    end

    private

    def build_initial_messages(prompt)
      if (mem = @memory.read)
        [{ role: "user", content: "<memory>\n#{mem}\n</memory>\n\n#{prompt}" }]
      else
        [{ role: "user", content: prompt }]
      end
    end

    def default_system_prompt
      parts = ["You are #{@name}, a #{@role} AI agent."]
      parts << "You can delegate tasks to sub-agents." if @role == :orchestrator
      parts << "Be concise, precise, and always complete your task."
      parts.join("\n")
    end

    def dispatch_tools(content_blocks)
      content_blocks.filter_map do |block|
        next unless block.type == "tool_use"

        tool = @tools[block.name]

        @hooks[:before_tool].each { |h| h.call(block.name, block.input) }
        result = tool.execute(block.input)
        @hooks[:after_tool].each  { |h| h.call(block.name, result) }

        {
          type:        "tool_result",
          tool_use_id: block.id,
          content:     [result]
        }
      end
    end

    def extract_text(content_blocks)
      content_blocks
        .select { |b| b.type == "text" }
        .map(&:text)
        .join
    end
  end
end
