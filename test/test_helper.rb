
$:.unshift( "#{File.expand_path(File.dirname(__FILE__))}/../lib" )

require 'rubygems'
require 'bundler/setup'

# Set-up SimpleCov (code coverage tool for Ruby 1.9)
if /^1.9/ === RUBY_VERSION
  require 'simplecov'
  SimpleCov.start do
    coverage_dir 'simplecov'
  end
end

require 'biomart'
require 'shoulda'
require 'vcr'

# Set-up VCR for mocking up web requests.
VCR.config do |c|
  if /^1\.8/ === RUBY_VERSION
    c.cassette_library_dir = 'test/vcr_cassettes_ruby1.8'
  elsif RUBY_VERSION == "1.9.1"
    c.cassette_library_dir = 'test/vcr_cassettes_ruby1.9.1'
  else
    c.cassette_library_dir = 'test/vcr_cassettes_ruby1.9.2+'
  end
  
  c.stub_with                :webmock
  c.ignore_localhost         = true
  c.default_cassette_options = { 
    :record            => :new_episodes, 
    :match_requests_on => [:uri, :method, :body]
  }
end
