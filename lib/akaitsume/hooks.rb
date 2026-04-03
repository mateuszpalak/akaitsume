# frozen_string_literal: true

module Akaitsume
  module Hooks
    EVENTS = %i[before_tool after_tool on_response on_error].freeze

    EVENTS.each do |event|
      define_method(event) do |&block|
        hooks[event] << block
      end
    end

    private

    def hooks
      @hooks ||= EVENTS.to_h { |e| [e, []] }
    end

    def fire(event, *args)
      hooks[event].each { |h| h.call(*args) }
    end
  end
end
