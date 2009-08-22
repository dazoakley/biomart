module Biomart
  class Attribute
    attr_reader :name, :display_name, :default
    
    def initialize(args)
      @name         = args["internalName"]
      @display_name = args["displayName"]
      @default      = args["default"] ? true : false
    end
    
  end
end