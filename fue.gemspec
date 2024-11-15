# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'fue/version'

Gem::Specification.new do |s|
  s.name = 'fue'
  s.bindir = 'bin'
  s.executables << 'fue'
  s.version = Fue::VERSION
  s.authors = ['Daniel Doubrovkine']
  s.email = 'dblock@dblock.org'
  s.platform = Gem::Platform::RUBY
  s.required_rubygems_version = '>= 1.3.6'
  s.files = Dir['{bin,lib}/**/*'] + Dir['*.md']
  s.require_paths = ['lib']
  s.homepage = 'http://github.com/dblock/fue'
  s.licenses = ['MIT']
  s.summary = 'Find an e-mail address of a GitHub user.'
  s.required_ruby_version = '>= 3.0'
  s.add_dependency 'faraday', '< 2'
  s.add_dependency 'github_api', '~> 0.19.0'
  s.add_dependency 'gli', '~> 2.17'
  s.add_dependency 'graphlient', '~> 0.6.0'
  s.metadata['rubygems_mfa_required'] = 'true'
end
