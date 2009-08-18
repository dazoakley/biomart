module Biomart
  class Database
    attr_reader :name, :display_name, :visible
    
    def initialize( server, args )
      if server.is_a? String
        @server = Server.new(server)
      else
        @server = server
      end
      
      @name         = args["name"]
      @display_name = args["displayName"]
      @visible      = args["visible"] ? true : false
      @datasets     = {}
    end
    
    def datasets
      if @datasets.empty?
        document = @server.request( 'GET', { :type => 'datasets', :mart => @name } )
        tsv_data = CSV.parse( document, "\t" )
        tsv_data.each do |t|
          if t[1]
            dataset_attr = {
              "name"         => t[1],
              "displayName"  => t[2],
              "visible"      => t[3]
            }
            @datasets[ dataset_attr["name"] ] = Dataset.new( @server, dataset_attr )
          end
        end
      end
      return @datasets
    end
    
  end
end