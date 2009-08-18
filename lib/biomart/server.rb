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
        url = @url + '?type=registry'
        document = REXML::Document.new( request( :url => url ) )
        REXML::XPath.each( document, "//MartURLLocation" ) do |d|
          @databases[ d.attributes["name"] ] = Database.new( @url, d.attributes )
        end
      end
      return @databases
    end
    
    def datasets
      if @datasets.empty?
        self.databases.each do |name,database|
          @datasets.merge!( database.datasets )
        end
      end
      return @datasets
    end
  end
end