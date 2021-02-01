require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'bundler/audit/task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
Bundler::Audit::Task.new
RuboCop::RakeTask.new

task default: ['bundle:audit', :rubocop, :spec]
