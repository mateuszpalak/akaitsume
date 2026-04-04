# frozen_string_literal: true

require 'test_helper'

describe Akaitsume::Tool::Registry do
  let(:fake_tool) do
    Class.new do
      include Akaitsume::Tool::Base
      tool_name 'fake'
      description 'A fake tool for testing'
      def call(input) = "fake: #{input['x']}"
    end
  end

  let(:registry) { Akaitsume::Tool::Registry.new }

  describe '#register' do
    it 'returns self for chaining' do
      result = registry.register(fake_tool)
      _(result).must_equal registry
    end
  end

  describe '#[]' do
    it 'returns an instance of the registered tool' do
      registry.register(fake_tool)
      _(registry['fake']).must_be_kind_of fake_tool
    end

    it 'caches the instance on repeated access' do
      registry.register(fake_tool)
      t1 = registry['fake']
      t2 = registry['fake']
      _(t1).must_be_same_as t2
    end

    it 'raises ToolNotFoundError for unknown name' do
      _ { registry['nope'] }.must_raise Akaitsume::ToolNotFoundError
    end
  end

  describe '#api_definitions' do
    it 'returns array of tool definition hashes' do
      registry.register(fake_tool)
      defs = registry.api_definitions
      _(defs.size).must_equal 1
      _(defs.first[:name]).must_equal 'fake'
    end
  end

  describe '#names' do
    it 'returns array of registered tool names' do
      registry.register(fake_tool)
      _(registry.names).must_equal ['fake']
    end
  end

  describe '.default_for' do
    it 'auto-discovers built-in tools' do
      cfg = Akaitsume::Config.new(workspace: make_tmp_dir, memory_dir: make_tmp_dir)
      mem = Akaitsume::Memory::FileStore.new(dir: cfg.memory_dir, agent_name: 'test')
      reg = Akaitsume::Tool::Registry.default_for(cfg, memory: mem)
      _(reg.names).must_include 'bash'
      _(reg.names).must_include 'files'
      _(reg.names).must_include 'http'
      _(reg.names).must_include 'memory'
    end
  end
end
