require "rubygems"
gem "hoe", ">= 2.1.0"
require "hoe"
require "fileutils"
require "./lib/biomart"

Hoe.plugin :newgem
# Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run "rake -T" to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec "biomart" do
  self.developer        "Darren Oakley", "daz.oakley@gmail.com"
  self.rubyforge_name   = self.name
  self.url              = "http://github.com/dazoakley/biomart"
  self.summary          = "A ruby API for interacting with Biomart services."
  self.description      = "A ruby API for interacting with Biomart services."
  self.extra_deps       = [["builder",">= 0"]]
  self.extra_dev_deps   = [["thoughtbot-shoulda",">=0"]]
  self.extra_rdoc_files = ["README.rdoc"]
end

require "newgem/tasks"
Dir["tasks/*.task"].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
# task :default => [:spec, :features]
