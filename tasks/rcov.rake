begin
  require "rcov/rcovtask"

  desc "Analyze code coverage with tests"
  Rcov::RcovTask.new do |t|
    t.libs << "test"
    t.test_files = FileList["test/test*.rb"]
    t.verbose = true
    t.rcov_opts << "--exclude /gems/,/Library/,spec,features"
  end
rescue LoadError
  if /^1\.8/ === RUBY_VERSION
    puts "[ERROR] Unable to load 'rcov' tasks - please install rcov"
  end
end

