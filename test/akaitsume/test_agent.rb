# frozen_string_literal: true

require 'test_helper'

describe Akaitsume::Agent do
  let(:dir) { make_tmp_dir }
  let(:config) { Akaitsume::Config.new(workspace: dir, memory_dir: dir, max_turns: 5) }
  let(:memory) { Akaitsume::Memory::FileStore.new(dir: dir, agent_name: 'test') }
  let(:logger) { Akaitsume::Logger.new(level: :error, output: StringIO.new) }

  # Stub provider that returns configurable responses
  let(:responses) { [] }
  let(:provider) do
    resps = responses
    Object.new.tap do |p|
      p.define_singleton_method(:chat) { |**_| resps.shift }
    end
  end

  let(:text_block) { TestHelpers::TextBlock.new(type: :text, text: 'hello from agent') }
  let(:tool_block) { TestHelpers::ToolUseBlock.new(type: :tool_use, name: 'fake', input: { 'x' => '1' }, id: 'call_1') }

  let(:fake_tool) do
    Class.new do
      include Akaitsume::Tool::Base
      tool_name 'fake'
      description 'fake'
      def call(input) = "result: #{input['x']}"
    end
  end

  let(:registry) do
    Akaitsume::Tool::Registry.new.tap { |r| r.register(fake_tool) }
  end

  let(:agent) do
    Akaitsume::Agent.new(
      name: 'test', role: :worker, config: config,
      provider: provider, tools: registry, memory: memory, logger: logger
    )
  end

  describe '.new' do
    it 'stores name and role' do
      _(agent.name).must_equal 'test'
      _(agent.role).must_equal :worker
    end
  end

  describe '#run' do
    describe 'single-turn (no tool use)' do
      before do
        responses << fake_response(
          stop_reason: :end_turn,
          content: [text_block],
          usage: { input_tokens: 10, output_tokens: 5 }
        )
      end

      it 'returns text response from provider' do
        result = agent.run('hello')
        _(result).must_equal 'hello from agent'
      end

      it 'fires on_response hook' do
        fired = []
        agent.on_response { |text| fired << text }
        agent.run('hello')
        _(fired).must_equal ['hello from agent']
      end

      it 'yields text to block' do
        yielded = nil
        agent.run('hello') { |text| yielded = text }
        _(yielded).must_equal 'hello from agent'
      end
    end

    describe 'with tool use' do
      before do
        responses << fake_response(
          stop_reason: :tool_use,
          content: [tool_block],
          usage: { input_tokens: 10, output_tokens: 5 }
        )
        responses << fake_response(
          stop_reason: :end_turn,
          content: [TestHelpers::TextBlock.new(type: :text, text: 'done')],
          usage: { input_tokens: 20, output_tokens: 10 }
        )
      end

      it 'dispatches tool and returns final text' do
        result = agent.run('use tool')
        _(result).must_equal 'done'
      end

      it 'fires before_tool and after_tool hooks' do
        events = []
        agent.before_tool { |name, _| events << "before:#{name}" }
        agent.after_tool { |name, _| events << "after:#{name}" }
        agent.run('use tool')
        _(events).must_equal ['before:fake', 'after:fake']
      end
    end

    describe 'max turns' do
      it 'raises MaxTurnsError when limit reached' do
        # Provider always returns tool_use — loop never ends
        5.times do
          responses << fake_response(stop_reason: :tool_use, content: [tool_block],
                                     usage: { input_tokens: 1, output_tokens: 1 })
        end
        _ { agent.run('loop forever') }.must_raise Akaitsume::MaxTurnsError
      end
    end

    describe 'memory injection' do
      it 'prepends memory to first user message' do
        memory.store('important fact')
        responses << fake_response(stop_reason: :end_turn, content: [text_block])

        session = Akaitsume::Session.new
        agent.run('hello', session: session)
        first_msg = session.messages.first[:content]
        _(first_msg).must_include '<memory>'
        _(first_msg).must_include 'important fact'
      end

      it 'uses plain prompt when memory is empty' do
        responses << fake_response(stop_reason: :end_turn, content: [text_block])

        session = Akaitsume::Session.new
        agent.run('plain hello', session: session)
        first_msg = session.messages.first[:content]
        _(first_msg).must_equal 'plain hello'
      end
    end

    describe 'session handling' do
      it 'uses provided session for continuity' do
        responses << fake_response(stop_reason: :end_turn, content: [text_block])
        session = Akaitsume::Session.new
        agent.run('hello', session: session)
        _(session.messages.size).must_be :>, 0
        _(session.turn_count).must_equal 1
      end
    end

    describe 'error handling' do
      it 'fires on_error hook and re-raises' do
        responses << nil # will cause NoMethodError
        errors = []
        agent.on_error { |e| errors << e.class }
        _ { agent.run('boom') }.must_raise NoMethodError
        _(errors).must_equal [NoMethodError]
      end
    end
  end

  describe '#spawn' do
    it 'creates a new Agent with given name and role' do
      responses << fake_response(stop_reason: :end_turn, content: [text_block])
      sub = agent.spawn(name: 'sub', role: :researcher)
      _(sub.name).must_equal 'sub'
      _(sub.role).must_equal :researcher
    end

    it 'shares the same config' do
      sub = agent.spawn(name: 'sub', role: :worker)
      _(sub.config).must_be_same_as agent.config
    end
  end
end
