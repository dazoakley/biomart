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
    
    def databases
      if @databases.empty?
        fetch_databases
      end
      return @databases.keys
    end
    
    def database_objects
      if @databases.empty?
        fetch_databases
      end
      return @databases
    end
    
    def datasets
      if @datasets.empty?
        fetch_datasets
      end
      return @datasets.keys
    end
    
    def dataset_objects
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
        self.database_objects.each do |name,database|
          @datasets.merge!( database.dataset_objects )
        end
      end
    
  end
end