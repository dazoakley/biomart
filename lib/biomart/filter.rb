module Biomart
  class Filter
    attr_reader :name, :display_name, :default, :default_value
    
    def initialize(args)
      @name          = args["internalName"]
      @display_name  = args["displayName"]
      @default       = args["defaultOn"] ? true : false
      @default_value = args["default_value"]
    end
    
  end
end