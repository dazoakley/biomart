require 'rubygems'
require 'rake'

require './lib/biomart'

begin
  require 'echoe'

  Echoe.new('biomart', '0.2.0') do |p|
    p.description    = 'A ruby API for interacting with Biomart XML based webservices.'
    p.url            = 'http://github.com/dazoakley/biomart'
    p.author         = 'Darren Oakley'
    p.email          = 'daz.oakley@gmail.com'
    p.ignore_pattern = ['tmp/*', 'script/*']
    p.dependencies   = [['builder','~>2']]
    p.development_dependencies = [['shoulda','>= 2.10'],['yard', '>= 0']]
  end

rescue LoadError => boom
  puts "You are missing a dependency required for meta-operations on this gem."
  puts "#{boom.to_s.capitalize}."
end

Dir['tasks/*.rake'].each { |t| load t }
task :default => [:test]
