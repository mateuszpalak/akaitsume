# frozen_string_literal: true

require 'yaml'
require 'fileutils'

module Akaitsume
  class Config
    DEFAULTS = {
      model: 'claude-haiku-4-5-20251001',
      max_turns: 20,
      max_tokens: 8096,
      workspace: Dir.home + '/.akaitsume/workspace',
      memory_dir: Dir.home + '/.akaitsume/memory',
      memory_backend: 'file',
      db_path: Dir.home + '/.akaitsume/akaitsume.db',
      log_level: 'info',
      tool_paths: []
    }.freeze

    attr_reader :model, :max_turns, :max_tokens, :workspace,
                :memory_dir, :memory_backend, :db_path, :log_level, :api_key,
                :tool_paths

    def self.load(path: nil)
      file_cfg = path ? YAML.safe_load_file(path, symbolize_names: true) : {}
      new(file_cfg)
    end

    def initialize(overrides = {})
      cfg = DEFAULTS.merge(overrides)
      @api_key        = ENV.fetch('ANTHROPIC_API_KEY') { raise ConfigError, 'ANTHROPIC_API_KEY not set' }
      @model          = cfg[:model]
      @max_turns      = cfg[:max_turns].to_i
      @max_tokens     = cfg[:max_tokens].to_i
      @workspace      = cfg[:workspace]
      @memory_dir     = cfg[:memory_dir]
      @memory_backend = cfg[:memory_backend].to_s
      @db_path        = cfg[:db_path]
      @log_level      = cfg[:log_level]
      @tool_paths     = Array(cfg[:tool_paths])
    end

    def ensure_directories!
      FileUtils.mkdir_p(@workspace)
      FileUtils.mkdir_p(@memory_dir)
      self
    end
  end
end
