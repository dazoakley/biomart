module Biomart
  class Server
    include Biomart
    
    attr_reader :url
    
    def initialize( url )
      @url = url or raise ArgumentError, "must pass :url"
      unless @url =~ /martservice/
        @url = @url + "/martservice"
      end
      
      @databases = {}
      @datasets  = {}
    end
    
    def list_databases
      if @databases.empty?
        fetch_databases
      end
      return @databases.keys
    end
    
    def databases
      if @databases.empty?
        fetch_databases
      end
      return @databases
    end
    
    def list_datasets
      if @datasets.empty?
        fetch_datasets
      end
      return @datasets.keys
    end
    
    def datasets
      if @datasets.empty?
        fetch_datasets
      end
      return @datasets
    end
    
    private
    
      def fetch_databases
        url = @url + '?type=registry'
        document = REXML::Document.new( request( :url => url ) )
        REXML::XPath.each( document, "//MartURLLocation" ) do |d|
          if d.attributes["visible"] === "1"
            @databases[ d.attributes["name"] ] = Database.new( @url, d.attributes )
          end
        end
      end
      
      def fetch_datasets
        self.databases.each do |name,database|
          @datasets.merge!( database.datasets )
        end
      end
    
  end
end