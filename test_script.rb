#!/usr/bin/env ruby -wKU

require "lib/biomart"

mart = Biomart::Server.new({ :url => "http://www.sanger.ac.uk/htgt/biomart" })
htgt = mart.databases["htgt"]
p htgt

