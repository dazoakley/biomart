require "uri"
require "net/http"
require "rexml/document"
require "csv"

require "rubygems"
require "builder"

module Biomart
  VERSION = "0.1.3"
  
  # This is the base Biomart error/exception class. Rescue it if 
  # you want to catch any exceptions that this code might raise.
  class BiomartError < StandardError
    attr_reader :data
    
    def initialize(data)
      @data = data
      super
    end
  end
  
  # Error class representing HTTP errors.
  class HTTPError      < BiomartError; end
  
  # Error class representing biomart filter errors.  Usually raised 
  # when a request is made for a incorrectly named (or non-existent) 
  # filter.
  class FilterError    < BiomartError; end
  
  # Error class representing biomart attribute errors.  Usually raised 
  # when a request is made for a incorrectly named (or non-existent) 
  # attribute.
  class AttributeError < BiomartError; end
  
  # Error class representing biomart dataset errors.  Usually raised 
  # when a request is made for a incorrectly named (or non-existent) 
  # dataset.
  class DatasetError   < BiomartError; end
  
  @@url    = 'http://www.biomart.org/biomart/martservice'
  @@client = Net::HTTP
  
  # Centralised request function for handling all of the HTTP requests 
  # to the biomart servers.
  def request( params={} )
    if Biomart.proxy or ENV['http_proxy']
      proxy_uri = Biomart.proxy
      proxy_uri ||= ENV['http_proxy']
      proxy = URI.parse( proxy_uri )
      @@client = Net::HTTP::Proxy( proxy.host, proxy.port )
    end
    
    params[:url] = URI.escape(params[:url])
    
    if params[:method] === 'post'
      res = @@client.post_form( URI.parse(params[:url]), { "query" => params[:query] } )
    else
      res = @@client.get_response( URI.parse(params[:url]) )
    end
    
    # Process the response code/body to catch errors.
    if res.code != "200"
      raise HTTPError.new(res.code), "HTTP error #{res.code}, please check your biomart server and URL settings."
    else
      if res.body =~ /ERROR/
        if res.body =~ /Filter (.+) NOT FOUND/
          raise FilterError.new(res.body), "Biomart error. Filter #{$1} not found."
        elsif res.body =~ /Attribute (.+) NOT FOUND/
          raise AttributeError.new(res.body), "Biomart error. Attribute #{$1} not found."
        elsif res.body =~ /Dataset (.+) NOT FOUND/
          raise DatasetError.new(res.body), "Biomart error. Dataset #{$1} not found."
        else
          raise BiomartError.new(res.body), "Biomart error."
        end
      end
    end
    
    return res.body
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
