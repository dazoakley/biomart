
$:.unshift( "#{File.expand_path(File.dirname(__FILE__))}/../lib" )

require 'rubygems'
require 'bundler/setup'
require 'shoulda'

# Set-up SimpleCov (code coverage tool for Ruby 1.9)
if /^1.9/ === RUBY_VERSION
  require 'simplecov'
  SimpleCov.start do
    coverage_dir 'simplecov'
  end
end

require 'biomart'
