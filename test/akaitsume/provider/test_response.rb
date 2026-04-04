# frozen_string_literal: true

require 'test_helper'

describe Akaitsume::Provider::Response do
  let(:response) do
    Akaitsume::Provider::Response.new(
      content: [{ type: :text, text: 'hello' }],
      stop_reason: :end_turn,
      model: 'claude-haiku-4-5-20251001',
      usage: { input_tokens: 100, output_tokens: 50 }
    )
  end

  describe '.new' do
    it 'creates an immutable value object' do
      _(response).must_be :frozen?
    end

    it 'defaults usage to empty hash' do
      r = Akaitsume::Provider::Response.new(content: [], stop_reason: :end_turn, model: 'test')
      _(r.usage).must_equal({})
    end
  end

  describe '#tool_use?' do
    it 'returns true when stop_reason is :tool_use' do
      r = Akaitsume::Provider::Response.new(
        content: [], stop_reason: :tool_use, model: 'test'
      )
      _(r.tool_use?).must_equal true
    end

    it 'returns false when stop_reason is :end_turn' do
      _(response.tool_use?).must_equal false
    end
  end

  describe '#input_tokens' do
    it 'returns value from usage hash' do
      _(response.input_tokens).must_equal 100
    end

    it 'returns 0 when usage has no input_tokens' do
      r = Akaitsume::Provider::Response.new(content: [], stop_reason: :end_turn, model: 'test')
      _(r.input_tokens).must_equal 0
    end
  end

  describe '#output_tokens' do
    it 'returns value from usage hash' do
      _(response.output_tokens).must_equal 50
    end
  end

  describe '#total_tokens' do
    it 'sums input and output tokens' do
      _(response.total_tokens).must_equal 150
    end
  end
end
