# frozen_string_literal: true

require "bundler/setup"
require "rspec/core/rake_task"
require "rubocop/rake_task"

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
end

RuboCop::RakeTask.new

task default: %i(spec rubocop)
