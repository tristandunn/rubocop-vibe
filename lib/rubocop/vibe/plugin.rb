# frozen_string_literal: true

require "lint_roller"

module RuboCop
  module Vibe
    class Plugin < LintRoller::Plugin
      # Return information about the plug-in.
      #
      # @return [LintRoller::About] Information about the plug-in.
      def about
        LintRoller::About.new(
          name:        "rubocop-vibe",
          version:     VERSION,
          homepage:    "https://github.com/tristandunn/rubocop-vibe",
          description: "A set of custom cops to use on AI generated code."
        )
      end

      # Return the rules for the plug-in.
      #
      # @param _context [LintRoller::Context] The runner context (unused).
      # @return [LintRoller::Rules] The rules for this plug-in.
      def rules(_context)
        LintRoller::Rules.new(
          type:          :path,
          config_format: :rubocop,
          value:         Pathname.new(__dir__).join("../../../config/default.yml")
        )
      end

      # Determine if the engine is supported.
      #
      # @param [LintRoller::Context] context The runner context.
      # @return [Boolean] If the engine is supported.
      def supported?(context)
        context.engine == :rubocop
      end
    end
  end
end
