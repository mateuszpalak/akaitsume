# frozen_string_literal: true

require "faraday"
require "json"

module Akaitsume
  module Tool
    class Http
      include Base

      tool_name   "http"
      description "Make HTTP requests. Supports GET, POST, PUT, PATCH, DELETE. " \
                  "Returns status code, response headers, and body (truncated to 4KB)."

      input_schema({
        type: "object",
        properties: {
          method: {
            type:        "string",
            enum:        %w[get post put patch delete],
            description: "HTTP method"
          },
          url: {
            type:        "string",
            description: "Full URL to request"
          },
          headers: {
            type:        "object",
            description: "Request headers as key-value pairs"
          },
          body: {
            type:        "string",
            description: "Request body (for POST/PUT/PATCH)"
          },
          timeout: {
            type:        "integer",
            description: "Timeout in seconds (default: 30)",
            default:     30
          }
        },
        required: %w[method url]
      })

      MAX_BODY = 4096

      def call(input)
        method  = (input["method"] || input[:method]).downcase.to_sym
        url     = input["url"] || input[:url]
        headers = input["headers"] || input[:headers] || {}
        body    = input["body"] || input[:body]
        timeout = (input["timeout"] || input[:timeout] || 30).to_i

        conn = Faraday.new do |f|
          f.options.timeout      = timeout
          f.options.open_timeout = timeout
        end

        response = conn.run_request(method, url, body, headers)

        resp_body = response.body.to_s
        truncated = resp_body.length > MAX_BODY

        parts = []
        parts << "[#{response.status}]"
        parts << resp_body[0...MAX_BODY]
        parts << "... (truncated, #{resp_body.length} bytes total)" if truncated
        parts.join("\n")
      rescue Faraday::Error => e
        "Error: #{e.class} - #{e.message}"
      end
    end
  end
end
