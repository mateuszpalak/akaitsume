# frozen_string_literal: true

require 'test_helper'

describe Akaitsume::Provider::Base do
  let(:named_provider) do
    Class.new do
      include Akaitsume::Provider::Base
      provider_name 'test-provider'
    end
  end

  let(:unnamed_provider) do
    Class.new do
      include Akaitsume::Provider::Base
    end
  end

  describe '.provider_name' do
    it 'stores and retrieves a custom name' do
      _(named_provider.provider_name).must_equal 'test-provider'
    end

    it 'returns class name when not explicitly set' do
      # Anonymous classes have nil name, but named classes return their name
      _(unnamed_provider.provider_name).must_be_nil
    end
  end

  describe '#chat' do
    it 'raises NotImplementedError' do
      provider = named_provider.new
      _ { provider.chat(messages: [], system: '', tools: [], model: '', max_tokens: 100) }
        .must_raise NotImplementedError
    end
  end
end
