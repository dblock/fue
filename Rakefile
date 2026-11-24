# frozen_string_literal: true

require 'rubygems'
require 'bundler/gem_tasks'

# Releases run through the GitHub Actions workflow, see RELEASING.md.
%w[release release:rubygem_push release:source_control_push].each do |name|
  Rake::Task[name].clear
  desc 'Disabled; releases run through GitHub Actions, see RELEASING.md'
  task(name) { abort "#{name} is disabled; releases run through GitHub Actions" }
end

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

begin
  require 'ruby-gem-release/workflow/ruby_gem'
  require 'ruby-gem-release/changelog'

  RubyGemRelease::Workflow::RubyGem.new(
    version: RubyGemRelease::Version::RubyConstant.new(path: 'lib/fue/version.rb', constant: 'VERSION'),
    changelog: RubyGemRelease::Changelog::Intridea.new(placeholder: '* Your contribution here.')
  ).install_tasks
rescue LoadError
  # The release Bundler group requires Ruby 3.3 or newer.
end

task default: default_tasks
