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
        url = @url + "?type=datasets&mart=#{@name}"
        document = request( :url => url )
        tsv_data = CSV.parse( document, "\t" )
        tsv_data.each do |t|
          if t[1]
            dataset_attr = {
              "name"         => t[1],
              "displayName"  => t[2],
              "visible"      => t[3]
            }
            @datasets[ dataset_attr["name"] ] = Dataset.new( @url, dataset_attr )
          end
        end
      end
      return @datasets
    end
    
  end
end