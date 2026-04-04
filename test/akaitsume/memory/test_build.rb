# frozen_string_literal: true

require 'test_helper'

describe Akaitsume::Memory do
  let(:dir) { make_tmp_dir }

  let(:file_config) do
    Akaitsume::Config.new(memory_backend: 'file', memory_dir: dir)
  end

  let(:sqlite_config) do
    Akaitsume::Config.new(memory_backend: 'sqlite', db_path: File.join(dir, 'test.db'))
  end

  describe '.build' do
    it 'returns FileStore for file backend' do
      mem = Akaitsume::Memory.build(file_config)
      _(mem).must_be_instance_of Akaitsume::Memory::FileStore
    end

    it 'returns SqliteStore for sqlite backend' do
      mem = Akaitsume::Memory.build(sqlite_config)
      _(mem).must_be_instance_of Akaitsume::Memory::SqliteStore
    end

    it 'defaults to FileStore for unknown backend' do
      cfg = Akaitsume::Config.new(memory_backend: 'unknown', memory_dir: dir)
      mem = Akaitsume::Memory.build(cfg)
      _(mem).must_be_instance_of Akaitsume::Memory::FileStore
    end

    it 'passes agent_name through' do
      mem = Akaitsume::Memory.build(file_config, agent_name: 'custom')
      mem.store('test')
      _(File.exist?(File.join(dir, 'custom.md'))).must_equal true
    end
  end
end
