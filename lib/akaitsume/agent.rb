# frozen_string_literal: true

module Akaitsume
  class Agent
    attr_reader :name, :role, :config, :logger

    def initialize(name: "akaitsume", role: :orchestrator, config: Config.load,
                   provider: nil, tools: nil, memory: nil, logger: nil)
      @name     = name
      @role     = role
      @config   = config
      @provider = provider || Provider::Anthropic.new(api_key: config.api_key)
      @memory   = memory || Memory::FileStore.new(dir: config.memory_dir, agent_name: name)
      @tools    = tools || Tool::Registry.default_for(config, memory: @memory)
      @logger   = logger || Logger.new(level: config.log_level)
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
        memory:   Memory::FileStore.new(dir: @config.memory_dir, agent_name: name),
        logger:   @logger
      )
    end

    # Register hooks
    def before_tool(&block) = @hooks[:before_tool] << block
    def after_tool(&block)  = @hooks[:after_tool] << block
    def on_response(&block) = @hooks[:on_response] << block

    # Run the agent loop.
    # Pass a Session for conversation continuity (chat mode).
    # Without a session, creates a temporary one for this single run.
    def run(prompt, system: nil, session: nil, &block)
      session ||= Session.new(system_prompt: system || default_system_prompt)
      sys = session.system_prompt || system || default_system_prompt

      inject_memory_and_prompt(session, prompt)

      loop do
        if session.turn_count >= @config.max_turns
          raise MaxTurnsError, "Exceeded max_turns (#{@config.max_turns})"
        end

        response = call_provider(sys, session)
        session.add_assistant(response.content)
        session.track_usage(response)

        if response.tool_use?
          tool_results = dispatch_tools(response.content)
          session.add_tool_results(tool_results)
        else
          text = extract_text(response.content)
          @hooks[:on_response].each { |h| h.call(text) }
          block&.call(text)
          return text
        end
      end
    end

    private

    def inject_memory_and_prompt(session, prompt)
      content = if (mem = @memory.read)
                  "<memory>\n#{mem}\n</memory>\n\n#{prompt}"
                else
                  prompt
                end
      session.add_user(content)
    end

    def call_provider(sys, session)
      @logger.debug("api_call", model: @config.model, messages: session.messages.size)

      response = @provider.chat(
        model:      @config.model,
        max_tokens: @config.max_tokens,
        system:     sys,
        tools:      @tools.api_definitions,
        messages:   session.messages
      )

      @logger.info("api_response",
                   stop_reason:   response.stop_reason,
                   input_tokens:  response.input_tokens,
                   output_tokens: response.output_tokens)

      response
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
        @logger.debug("tool_call", tool: block.name)

        t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = tool.execute(block.input)
        duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000).round

        @hooks[:after_tool].each { |h| h.call(block.name, result) }
        @logger.debug("tool_result", tool: block.name, duration_ms: duration_ms)

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
