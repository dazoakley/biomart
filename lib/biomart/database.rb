module Biomart
  # Class representation for a biomart database.
  # Will contain many Biomart::Dataset objects, and belong to a Biomart::Server.
  class Database
    include Biomart
    
    attr_reader :name, :display_name, :visible
    
    def initialize( url, args )
      @url = url or raise ArgumentError, "must pass :url"
      unless @url =~ /martservice/
        @url = @url + "/martservice"
      end
      
      @name         = args["name"] || args[:name]
      @display_name = args["displayName"] || args[:display_name]
      @visible      = ( args["visible"] || args[:visible] ) ? true : false
      @datasets     = {}
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
    
    private
    
      # Utility method to do the webservice call to the biomart server 
      # and collate/build the information about the datasets.
      def fetch_datasets
        url = @url + "?type=datasets&mart=#{@name}"
        document = request( :url => url )
        tsv_data = []
        
        if CSV.const_defined? :Reader
          # Ruby < 1.9 CSV code
          tsv_data = CSV.parse( document, "\t" )
        else
          # Ruby >= 1.9 CSV code
          tsv_data = CSV.parse( document, { :col_sep => "\t" } )
        end
        
        tsv_data.each do |t|
          if t[1] and ( t[3] === "1" )
            dataset_attr = {
              "name"         => t[1],
              "displayName"  => t[2],
              "visible"      => t[3]
            }
            @datasets[ dataset_attr["name"] ] = Dataset.new( @url, dataset_attr )
          end
        end
      end
    
  end
end