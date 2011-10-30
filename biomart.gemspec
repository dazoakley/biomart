# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "biomart/version"

Gem::Specification.new do |s|
  s.name        = "biomart"
  s.version     = Biomart::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Darren Oakley"]
  s.email       = ["daz.oakley@gmail.com"]
  s.homepage    = "http://github.com/dazoakley/biomart"
  s.summary     = "A ruby API for interacting with Biomart services."
  s.description = "A ruby API for interacting with Biomart XML based webservices."

  s.rubyforge_project = "biomart"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_runtime_dependency("builder", [">= 3.0"])
  s.add_development_dependency("rake", [">= 0"])
  s.add_development_dependency("shoulda", [">= 2.10"])
  s.add_development_dependency("simplecov", [">= 0"])
  s.add_development_dependency("awesome_print", [">= 0"])
  s.add_development_dependency("vcr", [">= 0"])
  s.add_development_dependency("webmock", [">= 0"])
end
