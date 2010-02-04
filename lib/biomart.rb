require "uri"
require "net/http"
require "rexml/document"
require "csv"

require "rubygems"
require "builder"

#begin
#  require "curb"
#  use_curb = true
#rescue LoadError
#  use_curb = false
#end
#CURB_AVAILABLE = use_curb

module Biomart
  VERSION = "0.1.5"
  
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
    net_http_request(params)
    
    #if CURB_AVAILABLE and ( Biomart.use_net_http != true )
    #  curb_request(params)
    #else
    #  net_http_request(params)
    #end
  end
  
  class << self
    attr_accessor :proxy, :timeout, :use_net_http
  end
  
  private
    
    # Utility function to perform the request method using the curb 
    # gem (a wrapper around libcurl) - supposed to be faster than 
    # Net::HTTP.
    def curb_request( params={} )
      client = Curl::Easy.new( params[:url] )
      
      if Biomart.timeout or params[:timeout]
        client.connect_timeout = params[:timeout] ? params[:timeout] : Biomart.timeout
      end
      
      if proxy_url() then client.proxy_url = proxy_url() end
      
      case params[:method]
      when 'post'
        client.http_post( Curl::PostField.content( "query", params[:query], "text/xml" ) )
      else
        client.http_get
      end
      
      check_response( client.body_str, client.response_code )
      
      return client.body_str
    end
    
    # Utility function to perform the request method using Net::HTTP.
    def net_http_request( params={} )
      uri          = URI.parse( params[:url] )
      client       = net_http_client()
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

      check_response( response.body, response.code )

      return response.body
    end
    
    # Utility function to create a Net::HTTP object.
    def net_http_client
      client = Net::HTTP
      if proxy_url()
        proxy  = URI.parse( proxy_url() )
        client = Net::HTTP::Proxy( proxy.host, proxy.port )
      end
      return client
    end
    
    # Utility function to determine if we need to use a proxy. If yes, 
    # returns the proxy url, if no, returns false.
    def proxy_url
      if Biomart.proxy or ENV['http_proxy'] or ENV['HTTP_PROXY']
        proxy_uri = Biomart.proxy
        proxy_uri ||= ENV['http_proxy']
        proxy_uri ||= ENV['HTTP_PROXY']
        
        return proxy_uri
      else
        return false
      end
    end
    
    # Utility function to test the response from a http request. 
    # Raises errors if appropriate.
    def check_response( body, code )
      # Process the response code/body to catch errors.
      if code.is_a?(String) then code = code.to_i end
      
      if code != 200 
        raise HTTPError.new(code), "HTTP error #{code}, please check your biomart server and URL settings."
      else
        if body =~ /ERROR/
          if body =~ /Filter (.+) NOT FOUND/
            raise FilterError.new(body), "Biomart error. Filter #{$1} not found."
          elsif body =~ /Attribute (.+) NOT FOUND/
            raise AttributeError.new(body), "Biomart error. Attribute #{$1} not found."
          elsif body =~ /Dataset (.+) NOT FOUND/
            raise DatasetError.new(body), "Biomart error. Dataset #{$1} not found."
          else
            raise BiomartError.new(body), "Biomart error."
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
