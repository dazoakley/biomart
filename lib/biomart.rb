$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require "uri"
require "net/http"
require "rexml/document"
require "csv"

require "rubygems"
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

  class Unauthorized  < StandardError; end
  class Unavailable   < StandardError; end
  class NotFound      < StandardError; end
  
  @@url = 'http://www.biomart.org/biomart/martservice'
  @@client = Net::HTTP
  
  def request( params={} )
    if Biomart.proxy
      proxy = URI.parse( Biomart.proxy )
      @@client = Net::HTTP::Proxy( proxy.host, proxy.port )
    end
    
    if params[:method].equal?('post')
      
    else
      get( params )
    end
  end
  
  def get( params={} )
    res = @@client.get_response( URI.parse(params[:url]) )
    return res.body
  end
  
  def post( params={} )
    
  end
  
  class << self
    attr_accessor :proxy
  end
  
end

directory = File.expand_path(File.dirname(__FILE__))

require File.join(directory, 'biomart', 'server')
require File.join(directory, 'biomart', 'database')
require File.join(directory, 'biomart', 'dataset')
require File.join(directory, 'biomart', 'filter')
require File.join(directory, 'biomart', 'attribute')
