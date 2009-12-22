begin
  require "metric_fu"
  MetricFu::Configuration.run do |config| 
    config.metrics  = [:churn, :saikuro, :flog, :flay, :reek, :roodi, :rcov]
    config.graphs   = [:flog, :flay, :reek, :roodi, :rcov]
    config.flog     = { :dirs_to_flog  => ["lib"] }
    config.flay     = { :dirs_to_flay  => ["lib"] }
    config.reek     = { :dirs_to_reek  => ["lib"] }
    config.roodi    = { :dirs_to_roodi => ["lib"] }
    config.rcov     = { 
                        :test_files => ["test/test_*.rb"],
                        :rcov_opts  => [
                          "--sort coverage", 
                          "--no-html", 
                          "--text-coverage",
                          "--no-color",
                          "--profile",
                          "--exclude /gems/,/Library/,spec,features"
                        ]
                      }
  end
rescue LoadError
end