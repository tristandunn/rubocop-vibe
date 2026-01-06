# frozen_string_literal: true

require "bundler/setup"
require "rspec/core/rake_task"
require "rubocop/rake_task"

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new

Rake::Task[:spec].enhance([:coverage])

desc "Enable test coverage"
task :coverage do
  ENV["COVERAGE"] = "1"
end

RuboCop::RakeTask.new

task default: %i(rubocop:autocorrect spec)
