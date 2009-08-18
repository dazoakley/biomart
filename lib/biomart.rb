$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require "rexml/document"
require "csv"

require "rubygems"
require "restclient"
require "builder"

module Biomart
  
  # Specialised classes for error reporting
  class BiomartError < StandardError
    attr_reader :data

    def initialize(data)
      @data = data
      super
    end
  end

  class General       < StandardError; end
  class Unauthorized  < StandardError; end
  class Unavailable   < StandardError; end
  class NotFound      < StandardError; end
  
end

directory = File.expand_path(File.dirname(__FILE__))

require File.join(directory, 'biomart', 'server')
require File.join(directory, 'biomart', 'database')
require File.join(directory, 'biomart', 'dataset')