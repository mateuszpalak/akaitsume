# frozen_string_literal: true

require 'test_helper'

describe Akaitsume::Tool::MemoryTool do
  let(:memory_dir) { make_tmp_dir }
  let(:memory) { Akaitsume::Memory::FileStore.new(dir: memory_dir, agent_name: 'test') }
  let(:tool) { Akaitsume::Tool::MemoryTool.new(memory: memory) }

  describe 'read' do
    it 'returns (empty memory) when no content' do
      result = tool.call('action' => 'read')
      _(result).must_equal '(empty memory)'
    end

    it 'returns memory content after store' do
      memory.store('important fact')
      result = tool.call('action' => 'read')
      _(result).must_include 'important fact'
    end
  end

  describe 'store' do
    it 'stores content to memory' do
      result = tool.call('action' => 'store', 'content' => 'remember this')
      _(result).must_equal 'Stored to memory.'
      _(memory.read).must_include 'remember this'
    end

    it 'returns error when content missing' do
      result = tool.call('action' => 'store')
      _(result).must_include 'Error'
    end
  end

  describe 'search' do
    it 'returns search results' do
      memory.store('ruby is great')
      result = tool.call('action' => 'search', 'query' => 'ruby')
      _(result).must_include 'ruby is great'
    end

    it 'returns error when query missing' do
      result = tool.call('action' => 'search')
      _(result).must_include 'Error'
    end
  end

  describe 'replace' do
    it 'replaces memory content' do
      memory.store('old stuff')
      tool.call('action' => 'replace', 'content' => 'new stuff')
      _(memory.read).must_include 'new stuff'
      _(memory.read).wont_include 'old stuff'
    end

    it 'returns error when content missing' do
      result = tool.call('action' => 'replace')
      _(result).must_include 'Error'
    end
  end
end
