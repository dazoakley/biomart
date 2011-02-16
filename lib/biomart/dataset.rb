module Biomart
  # Class represetation for a biomart dataset.
  # Can belong to a Biomart::Database and a Biomart::Server.
  class Dataset
    include Biomart
    
    attr_reader :name, :display_name, :visible
    
    # Creates a new Biomart::Dataset object.
    #
    # @param [String] url The URL location of the biomart server.
    # @param [Hash] args An arguments hash giving details of the dataset.
    #
    # arguments hash:
    #
    #   {
    #     :name         => String,     #
    #     "name"        => String,     #
    #     :display_name => {}          #
    #     
    #   }
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
    #   {
    #     :timeout => integer,     # set a timeout length for the request (secs)
    #     :filters => {}           # hash of key-value pairs (filter => search term)
    #   }
    def count( args={} )
      if args[:federate]
        raise Biomart::ArgumentError, "You cannot federate a count query."
      end
      
      if args[:required_attributes]
        raise Biomart::ArgumentError, "The :required_attributes option is not allowed on count queries."
      end
      
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
    #   {
    #     :process_results     => true/false,   # convert search results to object
    #     :timeout             => integer,      # set a timeout length for the request (secs)
    #     :filters             => {},           # hash of key-value pairs (filter => search term)
    #     :attributes          => [],           # array of attributes to retrieve
    #     :required_attributes => [],           # array of attributes that are required
    #     :federate => [
    #       {
    #         :dataset    => Biomart::Dataset, # A dataset object to federate with
    #         :filters    => {},               # hash of key-value pairs (filter => search term)
    #         :attributes => []                # array of attributes to retrieve
    #       }
    #     ]
    #   }
    #
    # Note, if you do not pass any filters or attributes arguments, the defaults 
    # for the dataset shall be used.
    #
    # Also, using the :required_attributes option - this performs AND logic and will require 
    # data to be returned in all of the listed attributes in order for it to be returned.
    #
    # By default will return a hash with the following:
    # 
    #   {
    #     :headers => [],   # array of headers
    #     :data    => []    # array of arrays containing search results
    #   }
    #
    # But with the :process_results option will return an array of hashes, 
    # where each hash represents a row of results (keyed by the attribute name).
    def search( args={} )
      if args[:required_attributes] and !args[:required_attributes].is_a?(Array)
        raise Biomart::ArgumentError, "The :required_attributes option must be passed as an array."
      end
      
      response = request(
        :method  => 'post',
        :url     => @url,
        :timeout => args[:timeout],
        :query   => generate_xml( process_xml_args(args) )
      )
      
      result = process_tsv( args, response )
      result = filter_data_rows( args, result ) if args[:required_attributes]
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
        dataset_xml( xml, self, { :filters => args[:filters], :attributes => args[:attributes] } )
        
        if args[:federate]
          args[:federate].each do |joined_dataset|
            unless joined_dataset[:dataset].is_a?(Biomart::Dataset)
              raise Biomart::ArgumentError, "You must pass a Biomart::Dataset object to the :federate[:dataset] option."
            end
            
            dataset_xml(
              xml,
              joined_dataset[:dataset],
              { :filters => joined_dataset[:filters], :attributes => joined_dataset[:attributes] }
            )
          end
        end
        
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
      
      # Utility function to process and test the arguments passed for 
      # the xml query.
      def process_xml_args( args={} )
        xml_args = {
          :filters    => args[:filters],
          :attributes => args[:attributes]
        }

        if args[:federate]
          unless args[:federate].is_a?(Array)
            raise Biomart::ArgumentError, "The :federate option must be passed as an array."
          end

          unless args[:federate].size == 1
            raise Biomart::ArgumentError, "Sorry, we can only federate two datasets at present.  This limitation shall be lifted in version 0.8 of biomart."
          end

          xml_args[:federate] = args[:federate]
        end

        return xml_args
      end
      
      # Helper function to produce the portion of the biomart xml for 
      # a dataset query.
      def dataset_xml( xml, dataset, args )
        xml.Dataset( :name => dataset.name, :interface => "default" ) {

          if args[:filters]
            args[:filters].each do |name,value|
              raise Biomart::ArgumentError, "The filter '#{name}' does not exist" if dataset.filters[name].nil?
              
              if dataset.filters[name].type == 'boolean'
                if [true,'included','only'].include?(value.downcase)
                  xml.Filter( :name => name, :excluded => '0' )
                elsif [false,'excluded'].include?(value.downcase)
                  xml.Filter( :name => name, :excluded => '1' )
                else
                  raise Biomart::ArgumentError, "The boolean filter '#{name}' can only accept 'true/included/only' or 'false/excluded' arguments."
                end
              else
                value = value.join(",") if value.is_a? Array
                xml.Filter( :name => name, :value => value )
              end
            end
          else
            dataset.filters.each do |name,filter|
              if filter.default?
                if filter.type == 'boolean'
                  xml.Filter( :name => name, :excluded => filter.default_value )
                else
                  xml.Filter( :name => name, :value => filter.default_value )
                end
              end
            end
          end

          unless args[:count]
            if args[:attributes]
              args[:attributes].each do |name|
                xml.Attribute( :name => name )
              end
            else
              dataset.attributes.each do |name,attribute|
                if attribute.default?
                  xml.Attribute( :name => name )
                end
              end
            end
          end

        }
      end
      
      # Utility function to transform the tab-separated data retrieved 
      # from the Biomart search query into a ruby object.
      def process_tsv( args, tsv )
        headers     = []
        parsed_data = []
        
        append_header_attributes_for_tsv( headers, self, args[:attributes] )

        if args[:federate]
          args[:federate].each do |joined_dataset|
            append_header_attributes_for_tsv( headers, joined_dataset[:dataset], joined_dataset[:attributes] )
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
      
      # Helper function to append the attribute names to the 'headers' array 
      # for processing the returned results.
      def append_header_attributes_for_tsv( headers, dataset, attributes )
        if attributes
          attributes.each do |attribute|
            headers.push(attribute)
          end
        else
          dataset.attributes.each do |name,attribute|
            if attribute.default?
              headers.push(name)
            end
          end
        end
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
      
      # Utility function to remove data rows from a search result that do not include 
      # the :required_attributes.
      def filter_data_rows( args, result )
        # Get the list of attributes searched for...
        attributes = args[:attributes] ? args[:attributes] : []
        if attributes.empty?
          self.attributes.each do |name,attribute|
            if attribute.default?
              attributes.push(name)
            end
          end
        end

        # Work out which attribute positions we need to test...
        positions_to_test = []
        attributes.each_index do |index|
          if args[:required_attributes].include?(attributes[index])
            positions_to_test.push(index)
          end
        end

        # Now go through the results and filter out the unwanted data...
        filtered_data = []
        result[:data].each do |data_row|
          save_row_count = 0

          positions_to_test.each do |position|
            save_row_count = save_row_count + 1 unless data_row[position].nil?
          end

          if save_row_count == positions_to_test.size
            filtered_data.push(data_row)
          end
        end

        return {
          :headers => result[:headers],
          :data    => filtered_data
        }
      end
  end
end