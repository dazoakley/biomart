module Biomart
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
    
      def fetch_datasets
        url = @url + "?type=datasets&mart=#{@name}"
        document = request( :url => url )
        tsv_data = CSV.parse( document, "\t" )
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