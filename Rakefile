require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

require "rdoc/task"
RDoc::Task.new :documentation do |rd|
 rd.rdoc_files.include("lib/**/*.rb")
 rd.rdoc_dir = "doc"
 rd.options << "--all"
end
