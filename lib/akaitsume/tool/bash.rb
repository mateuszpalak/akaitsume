# frozen_string_literal: true

require 'open3'
require 'timeout'

module Akaitsume
  module Tool
    class Bash
      include Base

      tool_name   'bash'
      description 'Execute a shell command and return stdout + stderr. ' \
                  'Use for file operations, running scripts, git commands, etc. ' \
                  'Commands run in the configured workspace directory.'

      input_schema({
                     type: 'object',
                     properties: {
                       command: {
                         type: 'string',
                         description: 'The shell command to execute'
                       },
                       timeout: {
                         type: 'integer',
                         description: 'Timeout in seconds (default: 30)',
                         default: 30
                       }
                     },
                     required: ['command']
                   })

      DANGEROUS_PATTERNS = [
        %r{\brm\s+-rf\s+[/~]}, # rm -rf / or ~
        /\bmkfs\b/,
        %r{\bdd\s+.*of=/dev/},
        %r{>\s*/dev/sd},
        /\bshutdown\b/,
        /\breboot\b/,
        /\bchmod\s+-R\s+777/,
        /\bcurl\b.*\|\s*\bsh\b/,   # curl | sh
        /\bwget\b.*\|\s*\bsh\b/    # wget | sh
      ].freeze

      def initialize(workspace:, blocked_commands: nil)
        @workspace = workspace
        @blocked_commands = blocked_commands || DANGEROUS_PATTERNS
      end

      def call(input)
        cmd     = input['command']
        timeout = (input['timeout'] || 30).to_i

        if (violation = detect_dangerous(cmd))
          return "BLOCKED: dangerous command pattern detected (#{violation}). " \
                 'If this is intentional, use the files tool or modify blocked_commands config.'
        end

        stdout, stderr, status = Timeout.timeout(timeout) do
          Open3.capture3(cmd, chdir: @workspace)
        end

        parts = []
        parts << stdout.strip unless stdout.strip.empty?
        parts << "[stderr] #{stderr.strip}" unless stderr.strip.empty?
        parts << "[exit #{status.exitstatus}]" unless status.success?
        parts.empty? ? '(no output)' : parts.join("\n")
      rescue Timeout::Error
        "Error: command timed out after #{(input['timeout'] || 30).to_i}s"
      rescue Errno::ENOENT => e
        "Error: #{e.message}"
      end

      private

      def detect_dangerous(cmd)
        @blocked_commands.each do |pattern|
          return pattern.source if pattern.match?(cmd)
        end
        nil
      end
    end
  end
end
