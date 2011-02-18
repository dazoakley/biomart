module Biomart
  # Class representation for a biomart filter. 
  # Will belong to a Biomart::Dataset.
  class Filter
    attr_reader :name, :display_name, :default_value, :qualifier, :type, :pointer_dataset, :pointer_filter
    
    def initialize(args)
      @name            = args["internalName"]
      @display_name    = args["displayName"]
      @default         = args["defaultOn"] ? true : false
      @default_value   = args["defaultValue"]
      @hidden          = args["hideDisplay"] ? true : false
      @qualifier       = args["qualifier"]
      @type            = args["type"]
      @multiple_values = args["multipleValues"] ? true : false
      
      @pointer_dataset   = args["pointerDataset"]
      @pointer_filter    = args["pointerFilter"]
      @pointer_interface = args["pointerInterface"]
      
      @type.downcase! unless @type.nil?
    end
    
    # Convenience method to see if this filter is hidden from 
    # the standard MartView interface.
    #
    # @return [Boolean] true/false
    def hidden?
      @hidden
    end
    
    # Convenience method to see if this filter would be 
    # enabled by default in the standard MartView interface.
    #
    # @return [Boolean] true/false
    def default?
      @default
    end
    
    # Convenience method to see if this filter allows multiple 
    # values to be passed to it.
    #
    # @return [Boolean] true/false
    def multiple_values?
      @multiple_values
    end
  end
end