# frozen_string_literal: true

require 'sqlite3'

module Akaitsume
  module Memory
    class SqliteStore
      include Base

      def initialize(db_path:, agent_name: 'agent')
        @agent = agent_name
        @db    = SQLite3::Database.new(db_path)
        @db.results_as_hash = true
        create_table
      end

      def read
        rows = @db.execute(
          'SELECT content, created_at FROM memories WHERE agent = ? ORDER BY id ASC',
          [@agent]
        )
        return nil if rows.empty?

        rows.map { |r| "## #{r['created_at']}\n#{r['content']}" }.join("\n\n")
      end

      def store(entry)
        @db.execute(
          'INSERT INTO memories (agent, content) VALUES (?, ?)',
          [@agent, entry.strip]
        )
      end

      def replace(content)
        @db.execute('DELETE FROM memories WHERE agent = ?', [@agent])
        store(content) unless content.to_s.strip.empty?
      end

      def search(query)
        rows = @db.execute(
          'SELECT content, created_at FROM memories WHERE agent = ? AND content LIKE ? ORDER BY id ASC',
          [@agent, "%#{query}%"]
        )
        return "(no matches for '#{query}')" if rows.empty?

        rows.map { |r| "[#{r['created_at']}] #{r['content']}" }.join("\n")
      end

      private

      def create_table
        @db.execute(<<~SQL)
          CREATE TABLE IF NOT EXISTS memories (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            agent      TEXT    NOT NULL,
            content    TEXT    NOT NULL,
            created_at TEXT    DEFAULT (datetime('now', 'localtime'))
          )
        SQL
      end
    end
  end
end
