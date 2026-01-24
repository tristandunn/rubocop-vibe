# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces alignment of consecutive instance variable assignments at the `=` operator.
      #
      # Consecutive assignments (with no blank lines between) should align their
      # `=` operators for better readability. Groups are broken by blank lines.
      #
      # @example
      #   # bad
      #   @user = create(:user)
      #   @character = create(:character)
      #   @input = "test"
      #
      #   # good
      #   @user      = create(:user)
      #   @character = create(:character)
      #   @input     = "test"
      #
      #   # good - blank line breaks the group
      #   @user      = create(:user)
      #   @character = create(:character)
      #
      #   @service    = Users::Activate.new
      #   @activation = service.call
      class ConsecutiveInstanceVariableAssignmentAlignment < Base
        extend AutoCorrector
        include AlignmentHelpers

        MSG = "Align consecutive instance variable assignments at the = operator."

        # Check block nodes for assignment alignment.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [void]
        def on_block(node)
          if node.body
            check_assignments_in_body(node.body)
          end
        end
        alias on_numblock on_block

        # Check method definitions for assignment alignment.
        #
        # @param [RuboCop::AST::Node] node The def node.
        # @return [void]
        def on_def(node)
          if node.body
            check_assignments_in_body(node.body)
          end
        end
        alias on_defs on_def

        private

        # Check assignments in a body node.
        #
        # @param [RuboCop::AST::Node] body The body node.
        # @return [void]
        def check_assignments_in_body(body)
          statements = extract_statements(body)

          return if statements.size < 2

          groups = group_consecutive_statements(statements, &:ivasgn_type?)

          groups.each { |group| check_group_alignment(group) }
        end

        # Check alignment for a group of assignments.
        #
        # @param [Array<RuboCop::AST::Node>] group The assignment group.
        # @return [void]
        def check_group_alignment(group)
          columns       = group.map { |asgn| asgn.loc.operator.column }
          target_column = columns.max

          group.each do |asgn|
            current_column = asgn.loc.operator.column

            next if current_column == target_column

            add_offense(asgn.loc.name) do |corrector|
              autocorrect_alignment(corrector, asgn, target_column)
            end
          end
        end

        # Auto-correct the alignment of an assignment.
        #
        # @param [RuboCop::AST::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] asgn The assignment node.
        # @param [Integer] target_column The target column for alignment.
        # @return [void]
        def autocorrect_alignment(corrector, asgn, target_column)
          variable_name_end = asgn.loc.name.end_pos
          operator_start    = asgn.loc.operator.begin_pos
          total_spaces      = calculate_total_spaces(asgn, target_column)

          corrector.replace(
            range_between(variable_name_end, operator_start),
            " " * total_spaces
          )
        end

        # Calculate total spaces needed for alignment.
        #
        # @param [RuboCop::AST::Node] asgn The assignment node.
        # @param [Integer] target_column The target column for alignment.
        # @return [Integer] The number of spaces (minimum 1).
        def calculate_total_spaces(asgn, target_column)
          current_column = asgn.loc.operator.column
          current_spaces = asgn.loc.operator.begin_pos - asgn.loc.name.end_pos
          spaces_needed  = target_column - current_column

          [1, current_spaces + spaces_needed].max
        end
      end
    end
  end
end
