require "uri"
require "net/http"
require "rexml/document"
require "csv"

require "rubygems"
require "builder"

module Biomart
  VERSION = "0.0.1"
  
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
    if Biomart.proxy or ENV['http_proxy']
      proxy_uri = Biomart.proxy
      proxy_uri ||= ENV['http_proxy']
      proxy = URI.parse( proxy_uri )
      @@client = Net::HTTP::Proxy( proxy.host, proxy.port )
    end
    
    params[:url] = URI.escape(params[:url])
    
    if params[:method] === 'post'
      res = post( params )
    else
      res = get( params )
    end
    
    return res.body
  end
  
  def get( params={} )
    res = @@client.get_response( URI.parse(params[:url]) )
    return res
  end
  
  def post( params={} )
    res = @@client.post_form( URI.parse(params[:url]), { "query" => params[:query] } )
    return res
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
