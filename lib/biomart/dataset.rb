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
    
    def filters
      if @filters.empty?
        fetch_configuration()
      end
      return @filters
    end
    
    def list_filters
      if @filters.empty?
        fetch_configuration()
      end
      return @filters.keys
    end
    
    def attributes
      if @attributes.empty?
        fetch_configuration()
      end
      return @attributes
    end
    
    def list_attributes
      if @attributes.empty?
        fetch_configuration()
      end
      return @attributes.keys
    end
    
    def count( args={} )
      args.merge!({ :count => "1" })
      result = request( :method => 'post', :url => @url, :query => generate_xml(args) )
      return result.to_i
    end
    
    # 
    def search( args={} )
      response = request( :method => 'post', :url => @url, :query => generate_xml(args) )
      result   = process_tsv( args, response )
      result   = convert_results_to_array_of_hashes( result ) if args[:process_results]
      return result
    end
    
    # Utility function to build the Biomart query XML
    def generate_xml( args={} )
      biomart_xml = ""
      xml = Builder::XmlMarkup.new( :target => biomart_xml, :indent => 2 )
      
      xml.instruct!
      xml.declare!( :DOCTYPE, :Query )
      xml.Query( :virtualSchemaName => "default", :formatter => "TSV", :header => "0", :uniqueRows => "1", :count => args[:count], :datasetConfigVersion => "0.6" ) {
        xml.Dataset( :name => @name, :interface => "default" ) {
          
          if args[:filters]
            args[:filters].each do |name,value|
              if value.is_a? Array
                value = value.join(",")
              end
              xml.Filter( :name => name, :value => value )
            end
          else
            self.filters.each do |name,filter|
              if filter.default
                xml.Filter( :name => name, :value => filter.default_value )
              end
            end
          end
          
          unless args[:count]
            if args[:attributes]
              args[:attributes].each do |name|
                xml.Attribute( :name => name )
              end
            else
              self.attributes.each do |name,attribute|
                if attribute.default
                  xml.Attribute( :name => name )
                end
              end
            end
          end
          
        }
      }
      
      return biomart_xml
    end
    
    # Utility function to transform the tab-separated data retrieved 
    # from the Biomart search query into a ruby object.
    def process_tsv( args, tsv )
      headers = []
      
      if args[:attributes]
        args[:attributes].each do |attribute|
          headers.push(attribute)
        end
      else
        self.attributes.each do |name,attribute|
          if attribute.default
            headers.push(name)
          end
        end
      end
      
      return {
        :headers => headers,
        :data    => CSV.parse( tsv, "\t" )
      }
    end
    
    # Utility function to quickly convert a search result into an array of hashes
    # (keyed by the attribute name) for easier processing - this is not done by 
    # default on all searches as this can cause a large overhead on big data returns.
    def convert_results_to_array_of_hashes( search_results )
      result_objects = []
      
      search_results[:data].each do |row|
        tmp = {}
        row.each_index do |index|
          tmp[ search_results[:headers][index] ] = row[index]
        end
        result_objects.push(tmp)
      end
      
      return result_objects
    end
    
    private
    
      # Utility function to retrieve and process the configuration 
      # xml for a dataset
      def fetch_configuration
        url = @url + "?type=configuration&dataset=#{@name}"
        document = REXML::Document.new( request( :url => url ) )

        # Top-Level filters...
        REXML::XPath.each( document, '//FilterDescription' ) do |f|
          unless f.attributes["displayType"].eql? "container"
            @filters[ f.attributes["internalName"] ] = Filter.new( f.attributes )
          end
        end
        
        # Filters nested inside containers...
        REXML::XPath.each( document, '//FilterDescription/Option' ) do |f|
          if f.attributes["displayType"] != nil
            @filters[ f.attributes["internalName"] ] = Filter.new( f.attributes )
          end
        end
        
        # Attributes are much simpler...
        REXML::XPath.each( document, '//AttributeDescription' ) do |a|
          @attributes[ a.attributes["internalName"] ] = Attribute.new( a.attributes )
        end
      end
    
  end
end