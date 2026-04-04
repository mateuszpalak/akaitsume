# frozen_string_literal: true

require 'test_helper'

describe Akaitsume::Hooks do
  let(:klass) do
    Class.new do
      include Akaitsume::Hooks
      public :fire, :hooks
    end
  end
  let(:obj) { klass.new }

  describe 'module inclusion' do
    it 'defines methods for each EVENT' do
      Akaitsume::Hooks::EVENTS.each do |event|
        _(obj).must_respond_to event
      end
    end
  end

  describe 'registering callbacks' do
    it 'accepts a block for each event' do
      obj.before_tool { 'called' }
      obj.on_error { 'error' }
      _(obj.hooks[:before_tool].size).must_equal 1
      _(obj.hooks[:on_error].size).must_equal 1
    end
  end

  describe '#fire' do
    it 'calls all registered callbacks with arguments' do
      results = []
      obj.before_tool { |name, input| results << [name, input] }
      obj.before_tool { |name, _| results << name }
      obj.fire(:before_tool, 'bash', { cmd: 'ls' })
      _(results).must_equal [['bash', { cmd: 'ls' }], 'bash']
    end

    it 'does nothing when no callbacks registered' do
      obj.fire(:on_response, 'text')
    end
  end

  describe 'lazy initialization' do
    it 'initializes hooks hash on first access' do
      _(obj.hooks).must_be_instance_of Hash
      _(obj.hooks.keys).must_equal Akaitsume::Hooks::EVENTS.to_a
    end
  end
end
