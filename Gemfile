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

group :lint do
  gem 'rubocop', '~> 1.92'
  gem 'rubocop-performance', require: false
  gem 'rubocop-prose', '~> 0.2', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
end

group :danger do
  gem 'danger', require: false
  gem 'danger-changelog', require: false
  gem 'danger-pr-comment', require: false
  gem 'danger-toc', require: false
end
