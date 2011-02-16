module Biomart
  # Class representation for a biomart server.
  # Will contain many Biomart::Database and Biomart::Dataset objects.
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
    
    # Returns an array of the database names (biomart 'name') 
    # for this dataset.
    #
    # @return [Array] An array of database names
    def list_databases
      if @databases.empty?
        fetch_databases
      end
      return @databases.keys
    end
    
    # Returns a hash (keyed by the biomart 'name' for the database) 
    # of all of the Biomart::Database objects belonging to this server.
    #
    # @return [Hash] A hash of Biomart::Database objects keyed by the database name
    def databases
      if @databases.empty?
        fetch_databases
      end
      return @databases
    end
    
    # Returns an array of the dataset names (biomart 'name') 
    # for this dataset.
    def list_datasets
      if @datasets.empty?
        fetch_datasets
      end
      return @datasets.keys
    end
    
    # Returns a hash (keyed by the biomart 'name' for the dataset) 
    # of all of the Biomart::Dataset objects belonging to this server.
    def datasets
      if @datasets.empty?
        fetch_datasets
      end
      return @datasets
    end
    
    # Simple heartbeat function to test that a Biomart server is online.
    # Returns true/false.
    def alive?
      begin
        @databases = {} # reset the databases store
        self.list_databases
      rescue Biomart::BiomartError => e
        return false
      else
        return true
      end
    end
    
    private
    
      # Utility method to do the webservice call to the biomart server 
      # and collate/build the information about the databases.
      def fetch_databases
        url = @url + '?type=registry'
        document = REXML::Document.new( request( :url => url ) )
        REXML::XPath.each( document, "//MartURLLocation" ) do |d|
          @databases[ d.attributes["name"] ] = Database.new( @url, d.attributes )
        end
      end
      
      # Utility function to collate all of the Biomart::Dataset objects 
      # contained within the Biomart::Database objects.
      def fetch_datasets
        self.databases.each do |name,database|
          @datasets.merge!( database.datasets )
        end
      end
    
  end
end