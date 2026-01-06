# frozen_string_literal: true

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
