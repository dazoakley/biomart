module Biomart
  class Dataset
    attr_reader :name, :display_name, :visible, :filters, :attributes
    
    def initialize( server, args )
      if server.is_a? String
        @server = Server.new(server)
      else
        @server = server
      end
      
      @name         = args["name"]
      @display_name = args["displayName"]
      @visible      = args["visible"]
      
      @filters      = {}
      @attributes   = {}
      @importables  = {}
      @exportables  = {}
      
      self.fetch_configuration
    end
    
    def fetch_configuration
      document = REXML::Document.new( @server.request( 'GET', { :type => 'configuration', :dataset => @name } ) )
      
      REXML::XPath.each( document, '//FilterDescription' ) do |f|
        @filters[ f.attributes["internalName"] ] = Filter.new( f.attributes )
      end
      
      REXML::XPath.each( document, '//AttributeDescription' ) do |a|
        @attributes[ a.attributes["internalName"] ] = Attribute.new( a.attributes )
      end
    end
    
  end
end