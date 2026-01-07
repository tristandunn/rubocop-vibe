# frozen_string_literal: true

require_relative "lib/rubocop/vibe/version"

Gem::Specification.new do |s|
  s.name        = "rubocop-vibe"
  s.version     = RuboCop::Vibe::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Tristan Dunn"]
  s.email       = "hello@tristandunn.com"
  s.homepage    = "https://github.com/tristandunn/rubocop-vibe"
  s.summary     = "A set of custom cops to use on AI generated code."
  s.description = "A set of custom cops to use on AI generated code."
  s.license     = "MIT"
  s.metadata    = {
    "bug_tracker_uri"            => "https://github.com/tristandunn/rubocop-vibe/issues",
    "changelog_uri"              => "https://github.com/tristandunn/rubocop-vibe/blob/main/CHANGELOG.markdown",
    "default_lint_roller_plugin" => "RuboCop::Vibe::Plugin",
    "rubygems_mfa_required"      => "true"
  }

  s.files        = Dir["config/**/*", "lib/**/*"].to_a
  s.require_path = "lib"

  s.required_ruby_version = ">= 4.0"

  s.add_dependency "lint_roller",         ">= 1.1.0"
  s.add_dependency "rubocop",             ">= 1.82.1"
  s.add_dependency "rubocop-performance", ">= 1.26.1"
  s.add_dependency "rubocop-rake",        ">= 0.7.1"
  s.add_dependency "rubocop-rspec",       ">= 3.8.0"
end
