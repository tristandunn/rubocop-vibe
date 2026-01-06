# frozen_string_literal: true

require "simplecov"
require "simplecov-console"

if ENV["CI"] || ENV["COVERAGE"]
  SimpleCov.formatter = SimpleCov::Formatter::Console
  SimpleCov.start do
    add_filter("spec/")

    enable_coverage  :branch
    minimum_coverage line: 100, branch: 100
  end
end

require "bundler/setup"
require "rubocop-vibe"
require "rubocop/rspec/support"

Bundler.require(:default, :development)

RSpec.configure do |config|
  config.expect_with :rspec do |rspec|
    rspec.syntax = :expect
  end

  # Raise errors for any deprecations.
  config.raise_errors_for_deprecations!
end
