# frozen_string_literal: true

require "yaml"

module Akaitsume
  class Config
    DEFAULTS = {
      model:        "claude-opus-4-6",
      max_turns:    20,
      max_tokens:   8096,
      workspace:    Dir.home + "/.akaitsume/workspace",
      memory_dir:   Dir.home + "/.akaitsume/memory",
      log_level:    "info"
    }.freeze

    attr_reader :model, :max_turns, :max_tokens, :workspace,
                :memory_dir, :log_level, :api_key

    def self.load(path: nil)
      file_cfg = path ? YAML.safe_load_file(path, symbolize_names: true) : {}
      new(file_cfg)
    end

    def initialize(overrides = {})
      cfg = DEFAULTS.merge(overrides)
      @api_key    = ENV.fetch("ANTHROPIC_API_KEY") { raise ConfigError, "ANTHROPIC_API_KEY not set" }
      @model      = cfg[:model]
      @max_turns  = cfg[:max_turns].to_i
      @max_tokens = cfg[:max_tokens].to_i
      @workspace  = cfg[:workspace]
      @memory_dir = cfg[:memory_dir]
      @log_level  = cfg[:log_level]

      FileUtils.mkdir_p(@workspace)
      FileUtils.mkdir_p(@memory_dir)
    end
  end
end
