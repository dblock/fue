$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'bundler/setup'
require 'rspec'

require 'tmpdir'
require 'fue'
require 'English'
require 'webmock/rspec'
require 'graphlient'
require 'recursive-open-struct'

RSpec.configure(&:raise_errors_for_deprecations!)

Dir[File.join(File.dirname(__FILE__), 'support', '**/*.rb')].each do |file|
  require file
end
