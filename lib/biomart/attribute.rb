module Biomart
  # Class representation for a biomart attribute. 
  # Will belong to a Biomart::Dataset.
  class Attribute
    attr_reader :name, :display_name
    
    def initialize(args)
      @name         = args["internalName"]
      @display_name = args["displayName"]
      @default      = args["default"] ? true : false
      @hidden       = args["hideDisplay"] ? true : false
    end
    
    # Convenience method to see if this attribute is hidden from 
    # the standard MartView interface.  Returns true/false.
    def hidden?
      @hidden
    end
    
    # Convenience method to see if this attribute would be 
    # enabled by default in the standard MartView interface.
    # Returns true/false.
    def default?
      @default
    end
  end
end