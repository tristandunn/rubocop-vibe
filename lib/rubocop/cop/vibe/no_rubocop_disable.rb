# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces that inline rubocop:disable directive comments are not used.
      #
      # This cop encourages fixing issues rather than disabling cops on a
      # per-line basis. If a cop needs to be disabled, it should be configured
      # globally in `.rubocop.yml` with proper justification.
      #
      # @example Bad - inline disable directive on a line
      #   def method
      #     do_something # rubocop_disable Style/SomeCop  (triggers offense)
      #   end
      #
      # @example Bad - block disable directive
      #   # rubocop_disable Style/SomeCop  (triggers offense)
      #   def method
      #     do_something
      #   end
      #   # rubocop_enable Style/SomeCop
      #
      # @example Good - fix the issue instead
      #   def method
      #     do_something_correctly
      #   end
      #
      # @example Good - configure globally in .rubocop.yml
      #   # Style/SomeCop:
      #   #   Enabled: false
      class NoRubocopDisable < Base
        MSG = "Do not use `# rubocop:disable`. Fix the issue or configure globally in `.rubocop.yml`."

        DISABLE_PATTERN = /\A#\s*rubocop\s*:\s*disable\b/i

        # Check for rubocop:disable comments.
        #
        # @return [void]
        def on_new_investigation
          processed_source.comments.each do |comment|
            next unless disable_comment?(comment)

            add_offense(comment)
          end
        end

        private

        # Check if the comment is a rubocop:disable directive.
        #
        # @param [Parser::Source::Comment] comment The comment to check.
        # @return [Boolean]
        def disable_comment?(comment)
          DISABLE_PATTERN.match?(comment.text)
        end
      end
    end
  end
end
