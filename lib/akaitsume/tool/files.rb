# frozen_string_literal: true

module Akaitsume
  module Tool
    class Files
      include Base

      tool_name   "files"
      description "Read, write, list, or delete files in the workspace. " \
                  "Actions: read, write, append, list, delete."

      input_schema({
        type: "object",
        properties: {
          action: {
            type:        "string",
            enum:        %w[read write append list delete],
            description: "Action to perform"
          },
          path: {
            type:        "string",
            description: "Relative path within workspace"
          },
          content: {
            type:        "string",
            description: "Content to write (for write/append actions)"
          },
          pattern: {
            type:        "string",
            description: "Glob pattern for list action (default: **/*)"
          }
        },
        required: ["action"]
      })

      def initialize(workspace:)
        @workspace = workspace
      end

      def call(input)
        action  = input["action"] || input[:action]
        path    = input["path"]   || input[:path]
        content = input["content"] || input[:content]
        pattern = input["pattern"] || input[:pattern] || "**/*"

        case action
        when "read"   then read(path)
        when "write"  then write(path, content)
        when "append" then append(path, content)
        when "list"   then list(pattern)
        when "delete" then delete(path)
        else "Unknown action: #{action}"
        end
      end

      private

      def full_path(rel)
        path = File.expand_path(rel, @workspace)
        raise "Path traversal denied" unless path.start_with?(@workspace)
        path
      end

      def read(rel)
        p = full_path(rel)
        raise "File not found: #{rel}" unless File.exist?(p)
        File.read(p)
      end

      def write(rel, content)
        p = full_path(rel)
        FileUtils.mkdir_p(File.dirname(p))
        File.write(p, content.to_s)
        "Written #{content.to_s.bytesize} bytes to #{rel}"
      end

      def append(rel, content)
        p = full_path(rel)
        FileUtils.mkdir_p(File.dirname(p))
        File.open(p, "a") { |f| f.write(content.to_s) }
        "Appended to #{rel}"
      end

      def list(pattern)
        files = Dir.glob(File.join(@workspace, pattern))
                   .map { |f| f.delete_prefix("#{@workspace}/") }
                   .reject { |f| File.directory?(File.join(@workspace, f)) }
        files.empty? ? "(no files)" : files.join("\n")
      end

      def delete(rel)
        p = full_path(rel)
        raise "File not found: #{rel}" unless File.exist?(p)
        File.delete(p)
        "Deleted #{rel}"
      end
    end
  end
end
