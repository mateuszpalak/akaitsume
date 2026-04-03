# frozen_string_literal: true

require 'faraday'
require 'json'
require 'resolv'
require 'uri'

module Akaitsume
  module Tool
    class Http
      include Base

      tool_name   'http'
      description 'Make HTTP requests. Supports GET, POST, PUT, PATCH, DELETE. ' \
                  'Returns status code, response headers, and body (truncated to 4KB). ' \
                  'Requests to private/internal networks are blocked by default.'

      input_schema({
                     type: 'object',
                     properties: {
                       method: {
                         type: 'string',
                         enum: %w[get post put patch delete],
                         description: 'HTTP method'
                       },
                       url: {
                         type: 'string',
                         description: 'Full URL to request'
                       },
                       headers: {
                         type: 'object',
                         description: 'Request headers as key-value pairs'
                       },
                       body: {
                         type: 'string',
                         description: 'Request body (for POST/PUT/PATCH)'
                       },
                       timeout: {
                         type: 'integer',
                         description: 'Timeout in seconds (default: 30)',
                         default: 30
                       }
                     },
                     required: %w[method url]
                   })

      MAX_BODY = 4096

      # CIDR ranges that are blocked by default (private/link-local/loopback)
      BLOCKED_RANGES = [
        IPAddr.new('127.0.0.0/8'), # loopback
        IPAddr.new('10.0.0.0/8'),        # private class A
        IPAddr.new('172.16.0.0/12'),     # private class B
        IPAddr.new('192.168.0.0/16'),    # private class C
        IPAddr.new('169.254.0.0/16'),    # link-local / cloud metadata
        IPAddr.new('0.0.0.0/8'),         # "this" network
        IPAddr.new('::1/128'),           # IPv6 loopback
        IPAddr.new('fc00::/7'),          # IPv6 unique local
        IPAddr.new('fe80::/10')          # IPv6 link-local
      ].freeze

      def initialize(blocked_ranges: nil)
        @blocked_ranges = blocked_ranges || BLOCKED_RANGES
      end

      def call(input)
        method  = input['method'].downcase.to_sym
        url     = input['url']
        headers = input['headers'] || {}
        body    = input['body']
        timeout = (input['timeout'] || 30).to_i

        validate_url!(url)

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

      private

      def validate_url!(url)
        uri = URI.parse(url)
        host = uri.host

        raise 'BLOCKED: invalid URL' unless host
        raise 'BLOCKED: only http/https allowed' unless %w[http https].include?(uri.scheme)

        # Resolve hostname to IP and check against blocked ranges
        ips = Resolv.getaddresses(host)
        raise "BLOCKED: cannot resolve host '#{host}'" if ips.empty?

        ips.each do |ip_str|
          ip = IPAddr.new(ip_str)
          if @blocked_ranges.any? { |range| range.include?(ip) }
            raise "BLOCKED: requests to private/internal networks are not allowed (#{host} -> #{ip_str})"
          end
        end
      rescue URI::InvalidURIError
        raise 'BLOCKED: malformed URL'
      end
    end
  end
end
