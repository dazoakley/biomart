require 'bundler'

Bundler::GemHelper.install_tasks

Dir['tasks/*.rake'].each { |t| load t }
task :default => [:test]
