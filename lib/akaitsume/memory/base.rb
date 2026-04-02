# frozen_string_literal: true

module Akaitsume
  module Memory
    module Base
      # Returns full memory content or nil if empty.
      def read
        raise NotImplementedError, "#{self.class}#read not implemented"
      end

      # Appends an entry to memory.
      def store(entry)
        raise NotImplementedError, "#{self.class}#store not implemented"
      end

      # Replaces entire memory content.
      def replace(content)
        raise NotImplementedError, "#{self.class}#replace not implemented"
      end

      # Searches memory for a query string, returns matching results.
      def search(query)
        raise NotImplementedError, "#{self.class}#search not implemented"
      end
    end
  end
end
