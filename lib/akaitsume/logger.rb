# frozen_string_literal: true

require "json"
require "time"

module Akaitsume
  class Logger
    LEVELS = { debug: 0, info: 1, warn: 2, error: 3 }.freeze

    def initialize(level: :info, output: $stderr)
      @level  = LEVELS.fetch(level.to_sym, 1)
      @output = output
    end

    def debug(message, **context) = log(:debug, message, **context)
    def info(message, **context)  = log(:info, message, **context)
    def warn(message, **context)  = log(:warn, message, **context)
    def error(message, **context) = log(:error, message, **context)

    private

    def log(level, message, **context)
      return if LEVELS[level] < @level

      entry = {
        ts:    Time.now.iso8601,
        level: level,
        msg:   message
      }
      entry.merge!(context) unless context.empty?

      @output.puts(JSON.generate(entry))
    end
  end
end
