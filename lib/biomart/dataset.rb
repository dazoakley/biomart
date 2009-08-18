module Biomart
  class Dataset
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
      
      @filters      = {}
      @attributes   = {}
      @importables  = {}
      @exportables  = {}
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
    
    def filters
      if @filters.empty?
        self.fetch_configuration
      end
      return @filters
    end
    
    def attributes
      if @attributes.empty?
        self.fetch_configuration
      end
      return @attributes
    end
    
    def count
      
    end
    
    def search
      
    end
    
    def xml
      biomart_xml = ""
      xml = Builder::XmlMarkup.new( :target => biomart_xml, :indent => 2 )

      xml.instruct!
      xml.declare!( :DOCTYPE, :Query )
      xml.Query( :virtualSchemaName => "default", :formatter => "TSV", :header => "0", :uniqueRows => "1", :count => "", :datasetConfigVersion => "0.6" ) {
        xml.Dataset( :name => @name, :interface => "default" ) {

          #if filters_to_use
          #  filters_to_use.each do |f|
          #    xml.Filter( :name => f, :value => query )
          #  end
          #end
          #
          #if attributes_to_use
          #  attributes_to_use.each do |a|
          #    xml.Attribute( :name => a )
          #  end
          #else
          #  self.attributes.each do |a|
          #    xml.Attribute( :name => a )
          #  end
          #end

        }
      }

      return biomart_xml
    end
    
  end
end