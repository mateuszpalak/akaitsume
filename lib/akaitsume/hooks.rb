# frozen_string_literal: true

module Akaitsume
  module Hooks
    EVENTS = %i[before_tool after_tool on_response on_error].freeze

    def self.included(base)
      base.define_method(:init_hooks) do
        @hooks = EVENTS.each_with_object({}) { |e, h| h[e] = [] }
      end
    end

    EVENTS.each do |event|
      define_method(event) do |&block|
        @hooks[event] << block
      end
    end

    private

    def fire(event, *args)
      @hooks.fetch(event, []).each { |h| h.call(*args) }
    end
  end
end
