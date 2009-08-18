module Biomart
  class Dataset
    include Biomart
    
    attr_reader :name, :display_name, :visible, :filters, :attributes
    
    def initialize( url, args )
      @url = url or raise ArgumentError, "must pass :url"
      unless @url =~ /martservice/
        @url = @url + "/martservice"
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
      url = @url + "?type=configuration&dataset=#{@name}"
      document = REXML::Document.new( request( :url => url ) )
      
      REXML::XPath.each( document, '//FilterDescription' ) do |f|
        @filters[ f.attributes["internalName"] ] = Filter.new( f.attributes )
      end
      
      REXML::XPath.each( document, '//AttributeDescription' ) do |a|
        @attributes[ a.attributes["internalName"] ] = Attribute.new( a.attributes )
      end
    end
    
  end
end