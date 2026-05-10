# frozen_string_literal: true

require_relative "lib/rubocop/vibe/version"

Gem::Specification.new do |spec|
  spec.name        = "rubocop-vibe"
  spec.version     = RuboCop::Vibe::VERSION
  spec.platform    = Gem::Platform::RUBY
  spec.authors     = ["Tristan Dunn"]
  spec.email       = "hello@tristandunn.com"
  spec.homepage    = "https://github.com/tristandunn/rubocop-vibe"
  spec.summary     = "A set of custom cops to use on AI generated code."
  spec.description = "A set of custom cops to use on AI generated code."
  spec.license     = "MIT"
  spec.metadata    = {
    "bug_tracker_uri"            => "https://github.com/tristandunn/rubocop-vibe/issues",
    "changelog_uri"              => "https://github.com/tristandunn/rubocop-vibe/blob/main/CHANGELOG.markdown",
    "default_lint_roller_plugin" => "RuboCop::Vibe::Plugin",
    "rubygems_mfa_required"      => "true"
  }

  spec.files        = Dir["config/**/*", "lib/**/*"].to_a
  spec.require_path = "lib"

  spec.required_ruby_version = ">= 4.0"

  spec.add_dependency "lint_roller",         ">= 1.1.0"
  spec.add_dependency "rubocop",             ">= 1.85.0"
  spec.add_dependency "rubocop-performance", ">= 1.26.1"
  spec.add_dependency "rubocop-rake",        ">= 0.7.1"
  spec.add_dependency "rubocop-rspec",       ">= 3.9.0"
end
