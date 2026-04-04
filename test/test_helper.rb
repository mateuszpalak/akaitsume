# frozen_string_literal: true

ENV['ANTHROPIC_API_KEY'] ||= 'test-key-for-minitest'

require 'minitest/autorun'
require 'minitest/mock'
require 'tmpdir'
require 'stringio'
require 'akaitsume'

module TestHelpers
  def make_tmp_dir
    dir = Dir.mktmpdir('akaitsume_test')
    (@_tmp_dirs ||= []) << dir
    dir
  end

  def fake_response(stop_reason: :end_turn, content: [], usage: {})
    Akaitsume::Provider::Response.new(
      content: content, stop_reason: stop_reason, model: 'test', usage: usage
    )
  end

  TextBlock = Struct.new(:type, :text, keyword_init: true)
  ToolUseBlock = Struct.new(:type, :name, :input, :id, keyword_init: true)
end

module Minitest
  class Spec
    include TestHelpers

    after do
      (@_tmp_dirs || []).each { |d| FileUtils.rm_rf(d) }
    end
  end
end
