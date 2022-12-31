# frozen_string_literal: true

require 'vcr'
require 'webmock/rspec'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/support/fixtures'
  config.hook_into :webmock
  config.default_cassette_options = { record: :new_episodes }
  config.configure_rspec_metadata!
  config.filter_sensitive_data('api-token') { ENV.fetch('GITHUB_ACCESS_TOKEN', nil) }
  config.before_record do |i|
    i.response.body.force_encoding('UTF-8')
  end
end
