# frozen_string_literal: true

require 'test_helper'
require 'resolv'

describe Akaitsume::Tool::Http do
  let(:http) { Akaitsume::Tool::Http.new }

  # Use execute() which catches errors and returns { type:, text: }
  describe 'SSRF blocking' do
    it 'blocks localhost / 127.0.0.1' do
      Resolv.stub(:getaddresses, ['127.0.0.1']) do
        result = http.execute('method' => 'get', 'url' => 'http://localhost/')
        _(result[:text]).must_include 'BLOCKED'
      end
    end

    it 'blocks 10.0.0.0/8 range' do
      Resolv.stub(:getaddresses, ['10.0.0.1']) do
        result = http.execute('method' => 'get', 'url' => 'http://internal.corp/')
        _(result[:text]).must_include 'BLOCKED'
      end
    end

    it 'blocks 172.16.0.0/12 range' do
      Resolv.stub(:getaddresses, ['172.16.0.1']) do
        result = http.execute('method' => 'get', 'url' => 'http://private.net/')
        _(result[:text]).must_include 'BLOCKED'
      end
    end

    it 'blocks 192.168.0.0/16 range' do
      Resolv.stub(:getaddresses, ['192.168.1.1']) do
        result = http.execute('method' => 'get', 'url' => 'http://router.local/')
        _(result[:text]).must_include 'BLOCKED'
      end
    end

    it 'blocks 169.254.0.0/16 (cloud metadata)' do
      Resolv.stub(:getaddresses, ['169.254.169.254']) do
        result = http.execute('method' => 'get', 'url' => 'http://metadata.google/')
        _(result[:text]).must_include 'BLOCKED'
      end
    end
  end

  describe 'URL validation' do
    it 'blocks URLs without host' do
      result = http.execute('method' => 'get', 'url' => 'http://')
      _(result[:text]).must_include 'BLOCKED'
    end

    it 'blocks non-http schemes' do
      result = http.execute('method' => 'get', 'url' => 'ftp://example.com/')
      _(result[:text]).must_include 'BLOCKED'
    end

    it 'blocks malformed URLs' do
      result = http.execute('method' => 'get', 'url' => ':::bad')
      _(result[:text]).must_include 'BLOCKED'
    end
  end

  describe 'successful requests' do
    it 'returns status and body for public URLs' do
      Resolv.stub(:getaddresses, ['93.184.216.34']) do
        fake_resp = Struct.new(:status, :body).new(200, 'OK response')
        fake_conn = Faraday.new { |f| f.adapter(:test) { |s| s.get('/test') { [200, {}, 'OK response'] } } }
        fake_conn.define_singleton_method(:run_request) { |*_args| fake_resp }

        Faraday.stub(:new, ->(*_a, **_k, &_b) { fake_conn }) do
          result = http.call('method' => 'get', 'url' => 'http://example.com/test')
          _(result).must_include '[200]'
          _(result).must_include 'OK response'
        end
      end
    end
  end

  describe 'body truncation' do
    it 'truncates at 4096 bytes' do
      large_body = 'x' * 5000
      Resolv.stub(:getaddresses, ['93.184.216.34']) do
        fake_resp = Struct.new(:status, :body).new(200, large_body)
        fake_conn = Faraday.new { |f| f.adapter(:test) }
        fake_conn.define_singleton_method(:run_request) { |*_args| fake_resp }

        Faraday.stub(:new, ->(*_a, **_k, &_b) { fake_conn }) do
          result = http.call('method' => 'get', 'url' => 'http://example.com/big')
          _(result).must_include 'truncated'
          _(result).must_include '5000 bytes'
        end
      end
    end
  end
end
