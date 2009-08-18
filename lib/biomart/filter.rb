module Biomart
  class Filter
    attr_reader :name, :display_name
    
    def initialize(args)
      @name         = args["internalName"]
      @display_name = args["displayName"]
    end
    
    
  end
end