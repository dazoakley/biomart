module Biomart
  class Dataset
    attr_reader :name, :display_name, :visible
    
    def initialize( server, args )
      if server.is_a? String
        @server = Server.new(server)
      else
        @server = server
      end
      
      @name         = args[:name]
      @display_name = args[:display_name]
      @visible      = args[:visible]
    end
    
    def fetch_configuration
      
    end
    
  end
end