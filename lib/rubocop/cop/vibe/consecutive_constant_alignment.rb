# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces alignment of consecutive constant assignments at the `=` operator.
      #
      # Consecutive constant assignments (with no blank lines between) should align their
      # `=` operators for better readability. Groups are broken by blank lines or non-constant
      # statements.
      #
      # @example
      #   # bad
      #   MINIMUM_NAME_LENGTH = 3
      #   MAXIMUM_NAME_LENGTH = 12
      #   ACTIVE_DURATION = 15.minutes
      #
      #   # good
      #   MINIMUM_NAME_LENGTH = 3
      #   MAXIMUM_NAME_LENGTH = 12
      #   ACTIVE_DURATION     = 15.minutes
      #
      #   # good - blank line breaks the group
      #   THROTTLE_LIMIT  = 10
      #   THROTTLE_PERIOD = 5
      #
      #   DEFAULT_VALUE = 0  # Separate group, not aligned
      class ConsecutiveConstantAlignment < Base
        extend AutoCorrector
        include AlignmentHelpers

        MSG = "Align consecutive constant assignments at the `=` operator."

        # Check class nodes for constant alignment.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @return [void]
        def on_class(node)
          if node.body
            check_constants_in_body(node.body)
          end
        end

        # Check module nodes for constant alignment.
        #
        # @param [RuboCop::AST::Node] node The module node.
        # @return [void]
        def on_module(node)
          if node.body
            check_constants_in_body(node.body)
          end
        end

        private

        # Check constants in a body node.
        #
        # @param [RuboCop::AST::Node] body The body node.
        # @return [void]
        def check_constants_in_body(body)
          statements = extract_statements(body)
          return if statements.size < 2

          groups = group_consecutive_statements(statements) { |s| s.casgn_type? && s.single_line? }
          groups.each { |group| check_group_alignment(group) }
        end

        # Check alignment for a group of constant assignments.
        #
        # @param [Array<RuboCop::AST::Node>] group The constant group.
        # @return [void]
        def check_group_alignment(group)
          columns       = group.map { |const| const.loc.operator.column }
          target_column = columns.max

          group.each do |const|
            current_column = const.loc.operator.column
            next if current_column == target_column

            add_offense(const.loc.name) do |corrector|
              autocorrect_alignment(corrector, const, target_column)
            end
          end
        end

        # Auto-correct the alignment of a constant assignment.
        #
        # @param [RuboCop::AST::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] const The constant assignment node.
        # @param [Integer] target_column The target column for alignment.
        # @return [void]
        def autocorrect_alignment(corrector, const, target_column)
          name_end       = const.loc.name.end_pos
          operator_start = const.loc.operator.begin_pos
          total_spaces   = calculate_total_spaces(const, target_column)

          corrector.replace(
            range_between(name_end, operator_start),
            " " * total_spaces
          )
        end

        # Calculate total spaces needed for alignment.
        #
        # @param [RuboCop::AST::Node] const The constant assignment node.
        # @param [Integer] target_column The target column for alignment.
        # @return [Integer] The number of spaces (minimum 1).
        def calculate_total_spaces(const, target_column)
          current_column = const.loc.operator.column
          current_spaces = const.loc.operator.begin_pos - const.loc.name.end_pos
          spaces_needed  = target_column - current_column

          [1, current_spaces + spaces_needed].max
        end
      end
    end
  end
end
