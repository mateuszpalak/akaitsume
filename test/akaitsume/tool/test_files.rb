# frozen_string_literal: true

require 'test_helper'

describe Akaitsume::Tool::Files do
  let(:workspace) { make_tmp_dir }
  let(:files) { Akaitsume::Tool::Files.new(workspace: workspace) }

  describe 'read' do
    it 'returns file contents' do
      File.write(File.join(workspace, 'test.txt'), 'hello')
      result = files.call('action' => 'read', 'path' => 'test.txt')
      _(result).must_equal 'hello'
    end

    it 'raises for missing file' do
      _ { files.call('action' => 'read', 'path' => 'nope.txt') }.must_raise RuntimeError
    end
  end

  describe 'write' do
    it 'creates file with content' do
      files.call('action' => 'write', 'path' => 'new.txt', 'content' => 'data')
      _(File.read(File.join(workspace, 'new.txt'))).must_equal 'data'
    end

    it 'creates intermediate directories' do
      files.call('action' => 'write', 'path' => 'sub/dir/file.txt', 'content' => 'deep')
      _(File.exist?(File.join(workspace, 'sub/dir/file.txt'))).must_equal true
    end

    it 'returns byte count message' do
      result = files.call('action' => 'write', 'path' => 'x.txt', 'content' => 'abc')
      _(result).must_include '3 bytes'
    end
  end

  describe 'append' do
    it 'appends to existing file' do
      File.write(File.join(workspace, 'log.txt'), 'line1')
      files.call('action' => 'append', 'path' => 'log.txt', 'content' => "\nline2")
      _(File.read(File.join(workspace, 'log.txt'))).must_equal "line1\nline2"
    end
  end

  describe 'list' do
    it 'lists files in workspace' do
      File.write(File.join(workspace, 'a.txt'), '')
      File.write(File.join(workspace, 'b.txt'), '')
      result = files.call('action' => 'list')
      _(result).must_include 'a.txt'
      _(result).must_include 'b.txt'
    end

    it 'returns (no files) for empty workspace' do
      result = files.call('action' => 'list')
      _(result).must_equal '(no files)'
    end

    it 'uses custom glob pattern' do
      File.write(File.join(workspace, 'a.rb'), '')
      File.write(File.join(workspace, 'b.txt'), '')
      result = files.call('action' => 'list', 'pattern' => '*.rb')
      _(result).must_include 'a.rb'
      _(result).wont_include 'b.txt'
    end
  end

  describe 'delete' do
    it 'deletes existing file' do
      path = File.join(workspace, 'del.txt')
      File.write(path, 'bye')
      files.call('action' => 'delete', 'path' => 'del.txt')
      _(File.exist?(path)).must_equal false
    end

    it 'raises for missing file' do
      _ { files.call('action' => 'delete', 'path' => 'nope.txt') }.must_raise RuntimeError
    end
  end

  describe 'path traversal prevention' do
    it 'blocks ../ traversal' do
      _ { files.call('action' => 'read', 'path' => '../../../etc/passwd') }.must_raise RuntimeError
    end
  end

  describe 'unknown action' do
    it 'returns unknown action message' do
      result = files.call('action' => 'zap')
      _(result).must_include 'Unknown action'
    end
  end
end
