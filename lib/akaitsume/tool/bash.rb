# frozen_string_literal: true

require "open3"

module Akaitsume
  module Tool
    class Bash
      include Base

      tool_name   "bash"
      description "Execute a shell command and return stdout + stderr. " \
                  "Use for file operations, running scripts, git commands, etc. " \
                  "Commands run in the configured workspace directory."

      input_schema({
        type: "object",
        properties: {
          command: {
            type:        "string",
            description: "The shell command to execute"
          },
          timeout: {
            type:        "integer",
            description: "Timeout in seconds (default: 30)",
            default:     30
          }
        },
        required: ["command"]
      })

      def initialize(workspace:)
        @workspace = workspace
      end

      def call(input)
        cmd     = input["command"] || input[:command]
        timeout = (input["timeout"] || input[:timeout] || 30).to_i

        stdout, stderr, status = Open3.capture3(
          cmd,
          chdir:   @workspace,
          timeout: timeout
        )

        parts = []
        parts << stdout.strip unless stdout.strip.empty?
        parts << "[stderr] #{stderr.strip}" unless stderr.strip.empty?
        parts << "[exit #{status.exitstatus}]" unless status.success?
        parts.empty? ? "(no output)" : parts.join("\n")
      rescue Errno::ENOENT => e
        "Error: #{e.message}"
      end
    end
  end
end
