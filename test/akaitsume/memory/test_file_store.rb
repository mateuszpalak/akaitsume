# frozen_string_literal: true

require 'test_helper'

describe Akaitsume::Memory::FileStore do
  let(:dir) { make_tmp_dir }
  let(:store) { Akaitsume::Memory::FileStore.new(dir: dir, agent_name: 'test') }

  describe '.new' do
    it 'creates the directory if missing' do
      new_dir = File.join(make_tmp_dir, 'nested')
      Akaitsume::Memory::FileStore.new(dir: new_dir, agent_name: 'x')
      _(File.directory?(new_dir)).must_equal true
    end

    it 'creates the memory file if missing' do
      store # force lazy evaluation
      _(File.exist?(File.join(dir, 'test.md'))).must_equal true
    end
  end

  describe '#read' do
    it 'returns nil when file is empty' do
      _(store.read).must_be_nil
    end

    it 'returns content when file has data' do
      store.store('hello')
      _(store.read).must_include 'hello'
    end
  end

  describe '#store' do
    it 'appends timestamped entry' do
      store.store('fact one')
      content = store.read
      _(content).must_match(/## \d{4}-\d{2}-\d{2}/)
      _(content).must_include 'fact one'
    end

    it 'preserves existing content' do
      store.store('first')
      store.store('second')
      content = store.read
      _(content).must_include 'first'
      _(content).must_include 'second'
    end
  end

  describe '#replace' do
    it 'overwrites all content' do
      store.store('old')
      store.replace('new')
      _(store.read).must_include 'new'
      _(store.read).wont_include 'old'
    end
  end

  describe '#search' do
    it 'finds matching lines (case-insensitive)' do
      store.store('Ruby is great')
      result = store.search('ruby')
      _(result).must_include 'Ruby is great'
    end

    it 'returns no-matches message when nothing found' do
      result = store.search('nonexistent')
      _(result).must_include 'no matches'
    end

    it 'includes line numbers in results' do
      store.store('findme')
      result = store.search('findme')
      _(result).must_match(/^L\d+:/)
    end
  end
end
