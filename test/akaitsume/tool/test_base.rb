# frozen_string_literal: true

require 'test_helper'

describe Akaitsume::Tool::Base do
  let(:complete_tool) do
    Class.new do
      include Akaitsume::Tool::Base
      tool_name 'test_tool'
      description 'A test tool'
      input_schema({ type: 'object', properties: { x: { type: 'string' } }, required: ['x'] })

      def call(input)
        "got: #{input['x']}"
      end
    end
  end

  let(:bare_tool) do
    Class.new { include Akaitsume::Tool::Base }
  end

  describe 'ClassMethods' do
    it 'stores and retrieves tool_name' do
      _(complete_tool.tool_name).must_equal 'test_tool'
    end

    it 'raises NotImplementedError when tool_name not set' do
      _ { bare_tool.tool_name }.must_raise NotImplementedError
    end

    it 'stores and retrieves description' do
      _(complete_tool.description).must_equal 'A test tool'
    end

    it 'raises NotImplementedError when description not set' do
      _ { bare_tool.description }.must_raise NotImplementedError
    end

    it 'returns default empty schema when not set' do
      # bare_tool.description raises, so create one with name+desc only
      klass = Class.new do
        include Akaitsume::Tool::Base
        tool_name 'x'
        description 'x'
      end
      schema = klass.input_schema
      _(schema[:type]).must_equal 'object'
      _(schema[:properties]).must_equal({})
    end

    it 'returns to_api_definition hash' do
      defn = complete_tool.to_api_definition
      _(defn[:name]).must_equal 'test_tool'
      _(defn[:description]).must_equal 'A test tool'
      _(defn[:input_schema][:type]).must_equal 'object'
    end
  end

  describe '#call' do
    it 'raises NotImplementedError on bare tool' do
      klass = Class.new do
        include Akaitsume::Tool::Base
        tool_name 'bare'
        description 'bare'
      end
      _ { klass.new.call({}) }.must_raise NotImplementedError
    end
  end

  describe '#execute' do
    it 'normalizes symbol keys to strings' do
      result = complete_tool.new.execute(x: 'hello')
      _(result[:text]).must_equal 'got: hello'
    end

    it 'wraps result in type/text hash' do
      result = complete_tool.new.execute('x' => 'world')
      _(result[:type]).must_equal 'text'
      _(result[:text]).must_equal 'got: world'
    end

    it 'catches errors and returns error text' do
      error_tool = Class.new do
        include Akaitsume::Tool::Base
        tool_name 'err'
        description 'err'
        def call(_input) = raise('boom')
      end
      result = error_tool.new.execute({})
      _(result[:text]).must_match(/Error: boom/)
    end
  end
end
