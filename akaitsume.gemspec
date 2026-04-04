# frozen_string_literal: true

require_relative 'lib/akaitsume/version'

Gem::Specification.new do |s|
  s.name        = 'akaitsume'
  s.version     = Akaitsume::VERSION
  s.summary     = '赤い爪 — A sharp, extensible AI agent for Ruby'
  s.description = 'Modular AI agent framework for Ruby'
  s.authors     = ['Mateusz Palak']
  s.license     = 'MIT'

  s.required_ruby_version = '>= 4.0'

  s.files = Dir['lib/**/*', 'bin/*', 'config/**/*', 'docs/**/*', 'README.md', 'LICENSE']
  s.executables = ['akaitsume']

  s.add_dependency 'anthropic', '>= 0.4'
  s.add_dependency 'base64'
  s.add_dependency 'dotenv'
  s.add_dependency 'faraday',    '>= 2.0'
  s.add_dependency 'sqlite3',    '>= 2.0'
  s.add_dependency 'thor',       '>= 1.0'
  s.add_dependency 'zeitwerk',   '>= 2.6'

  s.add_development_dependency 'rspec', '>= 3.12'
  s.add_development_dependency 'rubocop'
end
