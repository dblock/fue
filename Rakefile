# frozen_string_literal: true

require 'rubygems'
require 'bundler/gem_tasks'

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

default_tasks = %i[spec]

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
  default_tasks.unshift(:rubocop)
rescue LoadError
  # The lint Bundler group is not installed, e.g. with BUNDLE_WITHOUT=lint.
end

task default: default_tasks
