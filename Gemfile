# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :development, :test do
  gem 'rake'
  gem 'recursive-open-struct'
  gem 'rspec'
  gem 'vcr'
  gem 'webmock'
end

# rubocop-prose requires Ruby 3.2 or newer; Bundler resolves every group, even with BUNDLE_WITHOUT.
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.2')
  group :lint do
    gem 'rubocop', '~> 1.92'
    gem 'rubocop-performance', require: false
    gem 'rubocop-prose', '~> 0.2', require: false
    gem 'rubocop-rake', require: false
    gem 'rubocop-rspec', require: false
  end
end

group :danger do
  gem 'danger', require: false
  gem 'danger-changelog', require: false
  gem 'danger-pr-comment', require: false
  gem 'danger-toc', require: false
end
