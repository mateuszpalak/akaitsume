# frozen_string_literal: true

module Akaitsume
  module Memory
    class FileStore
      MEMORY_FILE = "MEMORY.md"

      def initialize(dir:, agent_name: "agent")
        @path = File.join(dir, "#{agent_name}.md")
        FileUtils.touch(@path) unless File.exist?(@path)
      end

      # Returns full memory content (injected into system prompt)
      def read
        content = File.read(@path).strip
        content.empty? ? nil : content
      end

      # Appends a timestamped entry
      def store(entry)
        File.open(@path, "a") do |f|
          f.puts "\n## #{Time.now.strftime('%Y-%m-%d %H:%M')}\n#{entry.strip}\n"
        end
      end

      # Replaces entire memory (for summarization)
      def replace(content)
        File.write(@path, content.to_s.strip + "\n")
      end

      # Simple keyword search
      def search(query)
        lines = File.readlines(@path)
        matches = lines.each_with_object([]).with_index do |(line, acc), i|
          acc << "L#{i + 1}: #{line.chomp}" if line.downcase.include?(query.downcase)
        end
        matches.empty? ? "(no matches for '#{query}')" : matches.join("\n")
      end
    end
  end
end
