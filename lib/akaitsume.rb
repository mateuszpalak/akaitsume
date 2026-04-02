# frozen_string_literal: true

require "zeitwerk"
require "anthropic"

loader = Zeitwerk::Loader.for_gem
loader.setup

module Akaitsume
  class Error < StandardError; end
  class MaxTurnsError < Error; end
  class ToolNotFoundError < Error; end
  class ConfigError < Error; end
end
