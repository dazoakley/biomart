
$:.unshift( "#{File.expand_path(File.dirname(__FILE__))}/../lib" )

require 'rubygems'
require 'bundler/setup'

# Set-up SimpleCov (code coverage tool for Ruby 1.9)
if /^1.9/ === RUBY_VERSION
  begin
    require 'simplecov'
    require 'simplecov-rcov'

    class SimpleCov::Formatter::MergedFormatter
      def format(result)
         SimpleCov::Formatter::HTMLFormatter.new.format(result)
         SimpleCov::Formatter::RcovFormatter.new.format(result)
      end
    end

    SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter
    SimpleCov.start do
      add_filter "/test/"
    end
  rescue LoadError
    puts "[ERROR] Unable to load 'simplecov' - please run 'bundle install'"
  end
end

require 'biomart'
require 'shoulda'
require 'vcr'
require 'awesome_print'

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
