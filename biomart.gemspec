# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{biomart}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Darren Oakley"]
  s.date = %q{2010-06-10}
  s.description = %q{A ruby API for interacting with Biomart XML based webservices.}
  s.email = ["daz.oakley@gmail.com"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.rdoc"]
  s.files = ["History.txt", "Manifest.txt", "README.rdoc", "Rakefile", "biomart.gemspec", "lib/biomart.rb", "lib/biomart/attribute.rb", "lib/biomart/database.rb", "lib/biomart/dataset.rb", "lib/biomart/filter.rb", "lib/biomart/server.rb", "script/console", "script/destroy", "script/generate", "tasks/metrics.task", "tasks/shoulda.task", "test/test_biomart.rb", "test/test_helper.rb"]
  s.homepage = %q{http://github.com/dazoakley/biomart}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{biomart}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A ruby API for interacting with Biomart services.}
  s.test_files = ["test/test_biomart.rb", "test/test_helper.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<builder>, [">= 0"])
      s.add_development_dependency(%q<shoulda>, [">= 2.10"])
      s.add_development_dependency(%q<hoe>, [">= 2.6.1"])
    else
      s.add_dependency(%q<builder>, [">= 0"])
      s.add_dependency(%q<shoulda>, [">= 2.10"])
      s.add_dependency(%q<hoe>, [">= 2.6.1"])
    end
  else
    s.add_dependency(%q<builder>, [">= 0"])
    s.add_dependency(%q<shoulda>, [">= 2.10"])
    s.add_dependency(%q<hoe>, [">= 2.6.1"])
  end
end
