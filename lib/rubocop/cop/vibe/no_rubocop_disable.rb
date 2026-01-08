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
      # Specific cops can be allowed via the `AllowedCops` configuration option.
      # If multiple cops are disabled in one comment, only the disallowed ones
      # will be flagged.
      #
      # @example Bad - inline disable directive
      #   do_something # rubocop_disable Style/SomeCop
      #
      # @example Bad - disable without specifying a cop
      #   # rubocop_disable all
      #   do_something
      #
      # @example Good - fix the issue instead
      #   do_something_correctly
      #
      # @example Good - configure globally in .rubocop.yml
      #   # In .rubocop.yml:
      #   # Style/SomeCop:
      #   #   Enabled: false
      #
      # @example AllowedCops: ['Rails/RakeEnvironment'] - allowed cop is not flagged
      #   # rubocop_disable Rails/RakeEnvironment
      #   task :my_task do
      #     # ...
      #   end
      class NoRubocopDisable < Base
        MSG        = "Do not disable `%<cops>s`. Fix the issue or configure globally in `.rubocop.yml`."
        MSG_NO_COP = "Do not use `# rubocop:disable`. Fix the issue or configure globally in `.rubocop.yml`."

        DISABLE_PATTERN  = /\A#\s*rubocop\s*:\s*disable\b/i
        COP_NAME_PATTERN = %r{[A-Za-z]+/[A-Za-z0-9]+}
        ALL_PATTERN      = /\brubocop\s*:\s*disable\s+all\b/i

        # Check for rubocop:disable comments.
        #
        # @return [void]
        def on_new_investigation
          processed_source.comments.each do |comment|
            next unless disable_comment?(comment)

            check_disabled_cops(comment)
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

        # Check disabled cops and flag disallowed ones.
        #
        # @param [Parser::Source::Comment] comment The comment to check.
        # @return [void]
        def check_disabled_cops(comment)
          cops = extract_cop_names(comment.text)

          if cops.empty?
            add_offense(comment, message: MSG_NO_COP)
          else
            disallowed = cops.reject { |cop| allowed_cop?(cop) }
            return if disallowed.empty?

            add_offense(comment, message: format(MSG, cops: disallowed.join(", ")))
          end
        end

        # Extract cop names from a rubocop:disable comment.
        #
        # @param [String] text The comment text.
        # @return [Array<String>]
        def extract_cop_names(text)
          text.scan(COP_NAME_PATTERN)
        end

        # Check if a cop is in the allowed list.
        #
        # @param [String] cop The cop name.
        # @return [Boolean]
        def allowed_cop?(cop)
          allowed_cops.include?(cop)
        end

        # Get the list of allowed cops from configuration.
        #
        # @return [Array<String>]
        def allowed_cops
          @allowed_cops ||= Array(cop_config.fetch("AllowedCops", []))
        end
      end
    end
  end
end
