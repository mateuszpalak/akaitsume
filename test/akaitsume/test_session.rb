# frozen_string_literal: true

require 'test_helper'

describe Akaitsume::Session do
  let(:session) { Akaitsume::Session.new(system_prompt: 'You are helpful.') }

  describe '.new' do
    it 'generates a 16-char hex id' do
      _(session.id).must_match(/\A[0-9a-f]{16}\z/)
    end

    it 'starts with empty messages' do
      _(session.messages).must_equal []
    end

    it 'stores system_prompt' do
      _(session.system_prompt).must_equal 'You are helpful.'
    end

    it 'defaults system_prompt to nil' do
      s = Akaitsume::Session.new
      _(s.system_prompt).must_be_nil
    end
  end

  describe '#add_user' do
    it 'appends a user-role message' do
      session.add_user('hello')
      _(session.messages.last).must_equal({ role: 'user', content: 'hello' })
    end
  end

  describe '#add_assistant' do
    it 'appends an assistant-role message' do
      session.add_assistant([{ type: :text, text: 'hi' }])
      _(session.messages.last[:role]).must_equal 'assistant'
    end
  end

  describe '#add_tool_results' do
    it 'appends results as user-role message' do
      results = [{ type: 'tool_result', tool_use_id: '123', content: [] }]
      session.add_tool_results(results)
      _(session.messages.last[:role]).must_equal 'user'
      _(session.messages.last[:content]).must_equal results
    end
  end

  describe '#increment_turn / #turn_count' do
    it 'starts at zero' do
      _(session.turn_count).must_equal 0
    end

    it 'increments by one each call' do
      session.increment_turn
      session.increment_turn
      _(session.turn_count).must_equal 2
    end
  end

  describe '#track_usage' do
    it 'accumulates tokens from response' do
      r1 = fake_response(usage: { input_tokens: 10, output_tokens: 5 })
      r2 = fake_response(usage: { input_tokens: 20, output_tokens: 15 })
      session.track_usage(r1)
      session.track_usage(r2)
      _(session.metadata[:input_tokens]).must_equal 30
      _(session.metadata[:output_tokens]).must_equal 20
    end
  end

  describe '#total_tokens' do
    it 'returns sum of input and output tokens' do
      session.track_usage(fake_response(usage: { input_tokens: 100, output_tokens: 50 }))
      _(session.total_tokens).must_equal 150
    end
  end
end
