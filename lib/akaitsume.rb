# frozen_string_literal: true

require 'zeitwerk'
require 'anthropic'

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect('cli' => 'CLI')
loader.setup

module Akaitsume
  class Error < StandardError; end
  class MaxTurnsError < Error; end
  class ToolNotFoundError < Error; end
  class ConfigError < Error; end

  module Memory
    # Factory: builds a memory store based on config
    def self.build(config, agent_name: 'akaitsume')
      case config.memory_backend
      when 'sqlite'
        SqliteStore.new(db_path: config.db_path, agent_name: agent_name)
      else
        FileStore.new(dir: config.memory_dir, agent_name: agent_name)
      end
    end
  end
end
