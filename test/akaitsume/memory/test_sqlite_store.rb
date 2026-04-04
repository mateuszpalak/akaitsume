# frozen_string_literal: true

require 'test_helper'

describe Akaitsume::Memory::SqliteStore do
  let(:db_path) { File.join(make_tmp_dir, 'test.db') }
  let(:store) { Akaitsume::Memory::SqliteStore.new(db_path: db_path, agent_name: 'test') }

  describe '.new' do
    it 'creates the memories table' do
      store
      db = SQLite3::Database.new(db_path)
      tables = db.execute("SELECT name FROM sqlite_master WHERE type='table'").flatten
      _(tables).must_include 'memories'
    end
  end

  describe '#read' do
    it 'returns nil when no entries' do
      _(store.read).must_be_nil
    end

    it 'returns formatted entries' do
      store.store('hello world')
      _(store.read).must_include 'hello world'
    end
  end

  describe '#store' do
    it 'inserts a new memory row' do
      store.store('a fact')
      _(store.read).must_include 'a fact'
    end
  end

  describe '#replace' do
    it 'deletes existing and inserts new content' do
      store.store('old')
      store.replace('new')
      _(store.read).must_include 'new'
      _(store.read).wont_include 'old'
    end
  end

  describe '#search' do
    it 'returns matching entries' do
      store.store('ruby rocks')
      result = store.search('ruby')
      _(result).must_include 'ruby rocks'
    end

    it 'returns no-matches message for no results' do
      result = store.search('nothing')
      _(result).must_include 'no matches'
    end
  end

  describe 'agent isolation' do
    it 'separates memories by agent_name' do
      agent_a = Akaitsume::Memory::SqliteStore.new(db_path: db_path, agent_name: 'alice')
      agent_b = Akaitsume::Memory::SqliteStore.new(db_path: db_path, agent_name: 'bob')
      agent_a.store('alice secret')
      agent_b.store('bob secret')
      _(agent_a.read).must_include 'alice secret'
      _(agent_a.read).wont_include 'bob secret'
      _(agent_b.read).must_include 'bob secret'
    end
  end
end
