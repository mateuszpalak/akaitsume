# frozen_string_literal: true

require 'test_helper'

describe Akaitsume::Config do
  describe '.load' do
    it 'returns Config with defaults when no path given' do
      cfg = Akaitsume::Config.load
      _(cfg.model).must_equal 'claude-haiku-4-5-20251001'
    end

    it 'merges YAML file values over defaults' do
      dir = Dir.mktmpdir
      path = File.join(dir, 'test.yml')
      File.write(path, "model: custom-model\nmax_turns: 5\n")
      cfg = Akaitsume::Config.load(path: path)
      _(cfg.model).must_equal 'custom-model'
      _(cfg.max_turns).must_equal 5
    ensure
      FileUtils.rm_rf(dir)
    end
  end

  describe '.new' do
    it 'uses DEFAULTS when no overrides provided' do
      cfg = Akaitsume::Config.new
      _(cfg.max_tokens).must_equal 8096
    end

    it 'merges overrides over defaults' do
      cfg = Akaitsume::Config.new(max_tokens: 4096)
      _(cfg.max_tokens).must_equal 4096
    end

    it 'reads api_key from ENV' do
      cfg = Akaitsume::Config.new
      _(cfg.api_key).must_equal ENV['ANTHROPIC_API_KEY']
    end

    it 'raises ConfigError when ANTHROPIC_API_KEY is missing' do
      original = ENV.delete('ANTHROPIC_API_KEY')
      _ { Akaitsume::Config.new }.must_raise Akaitsume::ConfigError
    ensure
      ENV['ANTHROPIC_API_KEY'] = original
    end

    it 'coerces max_turns to integer' do
      cfg = Akaitsume::Config.new(max_turns: '10')
      _(cfg.max_turns).must_equal 10
    end

    it 'wraps tool_paths in Array' do
      cfg = Akaitsume::Config.new(tool_paths: '/some/path')
      _(cfg.tool_paths).must_be_instance_of Array
    end

    it 'defaults tool_paths to empty array' do
      cfg = Akaitsume::Config.new
      _(cfg.tool_paths).must_equal []
    end
  end

  describe '#ensure_directories!' do
    it 'creates workspace and memory directories' do
      dir = Dir.mktmpdir
      ws = File.join(dir, 'ws')
      mem = File.join(dir, 'mem')
      cfg = Akaitsume::Config.new(workspace: ws, memory_dir: mem)
      cfg.ensure_directories!
      _(File.directory?(ws)).must_equal true
      _(File.directory?(mem)).must_equal true
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'returns self for chaining' do
      cfg = Akaitsume::Config.new(workspace: Dir.mktmpdir, memory_dir: Dir.mktmpdir)
      _(cfg.ensure_directories!).must_equal cfg
    end
  end

  describe 'DEFAULTS' do
    it 'is frozen' do
      _(Akaitsume::Config::DEFAULTS).must_be :frozen?
    end
  end
end
