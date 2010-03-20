module Biomart
  # Class represetation for a biomart dataset.
  # Can belong to a Biomart::Database and a Biomart::Server.
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
    
    # Returns a hash (keyed by the biomart 'internal_name' for the filter) 
    # of all of the Biomart::Filter objects belonging to this dataset.
    def filters
      if @filters.empty?
        fetch_configuration()
      end
      return @filters
    end
    
    # Returns an array of the filter names (biomart 'internal_name') 
    # for this dataset.
    def list_filters
      if @filters.empty?
        fetch_configuration()
      end
      return @filters.keys
    end
    
    # Returns a hash (keyed by the biomart 'internal_name' for the attribute) 
    # of all of the Biomart::Attribute objects belonging to this dataset.
    def attributes
      if @attributes.empty?
        fetch_configuration()
      end
      return @attributes
    end
    
    # Returns an array of the attribute names (biomart 'internal_name') 
    # for this dataset.
    def list_attributes
      if @attributes.empty?
        fetch_configuration()
      end
      return @attributes.keys
    end
    
    # Function to perform a Biomart count.  Returns an integer value for 
    # the result of the count query.
    #
    # optional arguments:
    #
    # :filters::         hash of key-value pairs (filter => search term)
    # :timeout::         set a timeout length for the request (secs)
    def count( args={} )
      result = request(
        :method  => 'post',
        :url     => @url,
        :timeout => args[:timeout],
        :query   => generate_xml(
          :filters    => args[:filters], 
          :attributes => args[:attributes], 
          :count      => "1"
        )
      )
      return result.to_i
    end
    
    # Function to perform a Biomart search.
    # 
    # optional arguments:
    #
    # :filters::         hash of key-value pairs (filter => search term)
    # :attributes::      array of attributes to retrieve
    # :process_results:: true/false - convert search results to object
    # :timeout::         set a timeout length for the request (secs)
    #
    # By default will return a hash with the following:
    # 
    # :headers::        array of headers
    # :data::           array of arrays containing search results
    #
    # But with the :process_results option will return an array of hashes, 
    # where each hash represents a row of results (keyed by the attribute name).
    def search( args={} )
      response = request(
        :method  => 'post',
        :url     => @url,
        :timeout => args[:timeout],
        :query   => generate_xml(
          :filters    => args[:filters],
          :attributes => args[:attributes]
        )
      )
      result = process_tsv( args, response )
      result = conv_results_to_a_of_h( result ) if args[:process_results]
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
              if filter.default?
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
                if attribute.default?
                  xml.Attribute( :name => name )
                end
              end
            end
          end
          
        }
      }
      
      return biomart_xml
    end
    
    # Simple heartbeat function to test that a Biomart server is online.
    # Returns true/false.
    def alive?
      server = Biomart::Server.new( @url )
      return server.alive?
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
      
      # Utility function to transform the tab-separated data retrieved 
      # from the Biomart search query into a ruby object.
      def process_tsv( args, tsv )
        headers     = []
        parsed_data = []

        if args[:attributes]
          args[:attributes].each do |attribute|
            headers.push(attribute)
          end
        else
          self.attributes.each do |name,attribute|
            if attribute.default?
              headers.push(name)
            end
          end
        end

        parsed_data = []
        if CSV.const_defined? :Reader
          # Ruby < 1.9 CSV code
          begin
            parsed_data = CSV.parse( tsv, "\t" )
          rescue CSV::IllegalFormatError => e
            parsed_data = parse_tsv_line_by_line( headers.size, tsv )
          end
        else
          # Ruby >= 1.9 CSV code
          begin
            parsed_data = CSV.parse( tsv, { :col_sep => "\t" } )
          rescue CSV::MalformedCSVError => e
            parsed_data = parse_tsv_line_by_line( headers.size, tsv )
          end
        end
        
        return {
          :headers => headers,
          :data    => parsed_data
        }
      end
      
      # Utility function to process TSV formatted data that raises errors. (Biomart 
      # has a habit of serving out this...) First attempts to use the CSV modules 
      # 'parse_line' function to read in the data, if that fails, tries to use split 
      # to recover the data.
      def parse_tsv_line_by_line( expected_row_size, tsv )
        parsed_data = []
        
        data_by_line = tsv.split("\n")
        data_by_line.each do |line|
          elements = []
          
          if CSV.const_defined? :Reader
            # Ruby < 1.9 CSV code
            elements = CSV::parse_line( line, "\t" )
          else
            # Ruby >= 1.9 CSV code
            begin
              elements = CSV::parse_line( line, { :col_sep => "\t" } )
            rescue CSV::MalformedCSVError => e
              elements = []
            end
          end
          
          if elements.size == 0
            # This is a bad line (causing the above Exception), try and use split to recover.
            elements = line.split("\t")
            if line =~ /\t$/
              # If the last attribute resturn is empty add a nil
              # value to the array as it would have been missed 
              # by the split function!
              elements.push(nil)
            end
            
            # Substitute blank strings for nils
            elements.map! do |elem|
              if elem === ""
                nil
              else
                elem
              end
            end
            
            # Add a safety clause...
            if elements.size === expected_row_size
              parsed_data.push(elements)
            end
          else
            parsed_data.push(elements)
          end
        end
        
        return parsed_data
      end
      
      # Utility function to quickly convert a search result into an array of hashes
      # (keyed by the attribute name) for easier processing - this is not done by 
      # default on all searches as this can cause a large overhead on big data returns.
      def conv_results_to_a_of_h( search_results )
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
    
  end
end