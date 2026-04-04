# frozen_string_literal: true

require 'test_helper'

describe Akaitsume::Provider::Anthropic do
  RawUsage = Struct.new(:input_tokens, :output_tokens, keyword_init: true)
  RawResponse = Struct.new(:content, :stop_reason, :model, :usage, keyword_init: true)

  let(:raw_response) do
    RawResponse.new(
      content: [TestHelpers::TextBlock.new(type: :text, text: 'hello')],
      stop_reason: :end_turn,
      model: 'claude-haiku-4-5-20251001',
      usage: RawUsage.new(input_tokens: 100, output_tokens: 50)
    )
  end

  # Stub messages resource that captures params
  let(:captured_params) { {} }
  let(:messages_stub) do
    resp = raw_response
    params_ref = captured_params
    Object.new.tap do |obj|
      obj.define_singleton_method(:create) do |**params|
        params_ref.merge!(params)
        resp
      end
    end
  end

  let(:client_stub) do
    msgs = messages_stub
    Object.new.tap do |obj|
      obj.define_singleton_method(:messages) { msgs }
    end
  end

  describe '#chat' do
    it 'returns a Provider::Response with correct fields' do
      ::Anthropic::Client.stub(:new, client_stub) do
        provider = Akaitsume::Provider::Anthropic.new(api_key: 'test')
        result = provider.chat(
          messages: [{ role: 'user', content: 'hi' }],
          system: 'Be helpful',
          tools: [{ name: 'bash' }],
          model: 'claude-haiku-4-5-20251001',
          max_tokens: 1024
        )
        _(result).must_be_instance_of Akaitsume::Provider::Response
        _(result.stop_reason).must_equal :end_turn
        _(result.input_tokens).must_equal 100
        _(result.output_tokens).must_equal 50
      end
    end

    it 'passes params to SDK client' do
      ::Anthropic::Client.stub(:new, client_stub) do
        provider = Akaitsume::Provider::Anthropic.new(api_key: 'test')
        provider.chat(
          messages: [{ role: 'user', content: 'hi' }],
          system: 'sys', tools: [{ name: 'x' }],
          model: 'test-model', max_tokens: 512
        )
        _(captured_params[:model]).must_equal 'test-model'
        _(captured_params[:max_tokens]).must_equal 512
        _(captured_params[:tools]).must_equal [{ name: 'x' }]
      end
    end

    it 'omits tools when empty' do
      ::Anthropic::Client.stub(:new, client_stub) do
        provider = Akaitsume::Provider::Anthropic.new(api_key: 'test')
        provider.chat(
          messages: [], system: '', tools: [],
          model: 'test', max_tokens: 100
        )
        _(captured_params.key?(:tools)).must_equal false
      end
    end
  end
end
