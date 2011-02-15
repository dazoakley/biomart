require "uri"
require "net/http"
require "cgi"
require "rexml/document"
require "csv"

require "rubygems"
require "builder"

module Biomart
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
  
  # Error class representing errors in the arguments being passed 
  # to the api.
  class ArgumentError < BiomartError; end
  
  # Centralised request function for handling all of the HTTP requests 
  # to the biomart servers.
  def request( params={} )
    if params[:url] =~ / /
      params[:url].gsub!(" ","+")
    end
    
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
  
  class << self
    attr_accessor :proxy, :timeout
  end
  
  private
    
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

require File.join(directory, 'biomart', 'version')
require File.join(directory, 'biomart', 'server')
require File.join(directory, 'biomart', 'database')
require File.join(directory, 'biomart', 'dataset')
require File.join(directory, 'biomart', 'filter')
require File.join(directory, 'biomart', 'attribute')
