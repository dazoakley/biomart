module Biomart
  class Server
    attr_reader :url
    
    # Instanciate the Biomart object
    def initialize(args)
      @url       = args[:url] or raise ArgumentError, "must pass :url"
      @databases = {}
      @datasets  = {}
      
      unless @url =~ /martservice/
        @url = @url + "/martservice"
      end
      
      @client = RestClient::Resource.new( @url )
      
      if args[:proxy] or ENV['http_proxy']
        args[:proxy] ||= ENV['http_proxy']
        RestClient.proxy = args[:proxy]
      end
    end
    
    def request( method, args )
      if method.equal?('GET')
        res = @client.get( args )
      else
        res = @client.post( args )
      end
      
      return res
    end
    
    def databases
      if @databases.empty?
        document = REXML::Document.new( request( 'GET', { :type => 'registry' } ) )
        REXML::XPath.each( document, '//MartURLLocation' ) do |d|
          @databases[ d.attributes["name"] ] = Database.new( self, d.attributes )
        end
      end
      return @databases
    end
    
    def datasets
      if @datasets.empty?
        self.databases.each do |name,database|
          @datasets.merge( database.datasets )
        end
      end
      return @datasets
    end
  end
end