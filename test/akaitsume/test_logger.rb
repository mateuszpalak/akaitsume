# frozen_string_literal: true

require 'test_helper'
require 'json'

describe Akaitsume::Logger do
  let(:output) { StringIO.new }
  let(:logger) { Akaitsume::Logger.new(level: :debug, output: output) }

  describe '#info' do
    it 'writes JSON with ts, level, msg keys' do
      logger.info('test message')
      entry = JSON.parse(output.string)
      _(entry).must_include 'ts'
      _(entry['level']).must_equal 'info'
      _(entry['msg']).must_equal 'test message'
    end

    it 'includes extra context keys' do
      logger.info('call', model: 'claude', tokens: 42)
      entry = JSON.parse(output.string)
      _(entry['model']).must_equal 'claude'
      _(entry['tokens']).must_equal 42
    end
  end

  describe '#debug' do
    it 'writes at debug level' do
      logger.debug('dbg')
      entry = JSON.parse(output.string)
      _(entry['level']).must_equal 'debug'
    end

    it 'is suppressed when logger level is info' do
      info_logger = Akaitsume::Logger.new(level: :info, output: output)
      info_logger.debug('should not appear')
      _(output.string).must_be :empty?
    end
  end

  describe '#warn' do
    it 'writes at warn level' do
      logger.warn('warning')
      _(JSON.parse(output.string)['level']).must_equal 'warn'
    end
  end

  describe '#error' do
    it 'writes at error level' do
      logger.error('failure')
      _(JSON.parse(output.string)['level']).must_equal 'error'
    end

    it 'is not suppressed at warn level' do
      warn_logger = Akaitsume::Logger.new(level: :warn, output: output)
      warn_logger.error('critical')
      _(output.string).wont_be :empty?
    end
  end

  describe 'level filtering' do
    it 'suppresses debug and info when level is warn' do
      warn_logger = Akaitsume::Logger.new(level: :warn, output: output)
      warn_logger.debug('no')
      warn_logger.info('no')
      _(output.string).must_be :empty?
    end
  end
end
