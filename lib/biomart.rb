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
  
  # Centralised request function for handling all of the HTTP requests 
  # to the biomart servers.
  def request( params={} )
    params[:url] = URI.escape( params[:url] )
    uri          = URI.parse( params[:url] )
    client       = http_client()
    req          = nil
    response     = nil
    
    case params[:method]
    when 'post'
      req           = Net::HTTP::Post.new(uri.path)
      req.form_data = { "query" => params[:query] }
    else
      req           = Net::HTTP::Get.new(uri.request_uri)
    end
    
    client.start(uri.host, uri.port) do |http|
      if Biomart.timeout or params[:timeout]
        http.read_timeout = params[:timeout] ? params[:timeout] : Biomart.timeout
        http.open_timeout = params[:timeout] ? params[:timeout] : Biomart.timeout
      end
      response = http.request(req)
    end
    
    check_response( response )
    
    return response.body
  end
  
  class << self
    attr_accessor :proxy, :timeout
  end
  
  private
    
    # Utility function to create a Net::HTTP object...
    def http_client
      client = Net::HTTP
      if Biomart.proxy or ENV['http_proxy'] or ENV['HTTP_PROXY']
        proxy_uri = Biomart.proxy
        proxy_uri ||= ENV['http_proxy']
        proxy_uri ||= ENV['HTTP_PROXY']
        proxy = URI.parse( proxy_uri )
        client = Net::HTTP::Proxy( proxy.host, proxy.port )
      end
      return client
    end
    
    # Utility function to test the response from a http request. 
    # Raises errors if appropriate.
    def check_response( response )
      # Process the response code/body to catch errors.
      if response.code != "200"
        raise HTTPError.new(response.code), "HTTP error #{response.code}, please check your biomart server and URL settings."
      else
        if response.body =~ /ERROR/
          if response.body =~ /Filter (.+) NOT FOUND/
            raise FilterError.new(response.body), "Biomart error. Filter #{$1} not found."
          elsif response.body =~ /Attribute (.+) NOT FOUND/
            raise AttributeError.new(response.body), "Biomart error. Attribute #{$1} not found."
          elsif response.body =~ /Dataset (.+) NOT FOUND/
            raise DatasetError.new(response.body), "Biomart error. Dataset #{$1} not found."
          else
            raise BiomartError.new(response.body), "Biomart error."
          end
        end
      end
    end
  
end

directory = File.expand_path(File.dirname(__FILE__))

require File.join(directory, 'biomart', 'server')
require File.join(directory, 'biomart', 'database')
require File.join(directory, 'biomart', 'dataset')
require File.join(directory, 'biomart', 'filter')
require File.join(directory, 'biomart', 'attribute')
