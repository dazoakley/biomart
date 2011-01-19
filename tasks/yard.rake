begin
  require "yard"
  
  YARD::Rake::YardocTask.new do |t|
    t.files   = ['lib/**/*.rb']
  end
rescue LoadError
  puts "[ERROR] Unable to load 'yard' tasks - please install yard"
end
