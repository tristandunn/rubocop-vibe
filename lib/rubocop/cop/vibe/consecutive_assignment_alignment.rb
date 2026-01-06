# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces alignment of consecutive variable assignments at the `=` operator.
      #
      # Consecutive assignments (with no blank lines between) should align their
      # `=` operators for better readability. Groups are broken by blank lines.
      #
      # @example
      #   # bad
      #   user = create(:user)
      #   character = create(:character)
      #   input = "test"
      #
      #   # good
      #   user      = create(:user)
      #   character = create(:character)
      #   input     = "test"
      #
      #   # good - blank line breaks the group
      #   user      = create(:user)
      #   character = create(:character)
      #
      #   service = Users::Activate.new  # Separate group, not aligned
      class ConsecutiveAssignmentAlignment < Base
        extend AutoCorrector

        MSG = "Align consecutive assignments at the = operator."

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

          groups = group_consecutive_assignments(statements)
          groups.each { |group| check_group_alignment(group) }
        end

        # Extract statements from a body node.
        #
        # @param [RuboCop::AST::Node] body The body node.
        # @return [Array<RuboCop::AST::Node>]
        def extract_statements(body)
          if body.begin_type?
            body.children
          else
            [body]
          end
        end

        # Group consecutive assignments together.
        #
        # @param [Array<RuboCop::AST::Node>] statements The statements.
        # @return [Array<Array<RuboCop::AST::Node>>] Groups of consecutive assignments.
        def group_consecutive_assignments(statements)
          groups        = []
          current_group = []
          previous_line = nil

          statements.each do |statement|
            current_group, previous_line = process_statement(statement, current_group, previous_line, groups)
          end

          finalize_groups(groups, current_group)
        end

        # Process a single statement for grouping.
        #
        # @param [RuboCop::AST::Node] statement The statement.
        # @param [Array<RuboCop::AST::Node>] current_group The current group.
        # @param [Integer, nil] previous_line The previous line number.
        # @param [Array<Array<RuboCop::AST::Node>>] groups The groups.
        # @return [Array] The updated current_group and previous_line.
        def process_statement(statement, current_group, previous_line, groups)
          if local_variable_assignment?(statement)
            current_group = handle_assignment(statement, current_group, previous_line, groups)
          else
            save_group_if_valid(groups, current_group)
            current_group = []
          end
          [current_group, statement.loc.last_line]
        end

        # Handle an assignment statement.
        #
        # @param [RuboCop::AST::Node] statement The assignment statement.
        # @param [Array<RuboCop::AST::Node>] current_group The current group.
        # @param [Integer, nil] previous_line The previous line number.
        # @param [Array<Array<RuboCop::AST::Node>>] groups The groups.
        # @return [Array<RuboCop::AST::Node>] The updated current group.
        def handle_assignment(statement, current_group, previous_line, groups)
          if previous_line && statement.loc.line - previous_line > 1
            save_group_if_valid(groups, current_group)
            current_group = []
          end
          current_group << statement
          current_group
        end

        # Save group if it has multiple assignments.
        #
        # @param [Array<Array<RuboCop::AST::Node>>] groups The groups.
        # @param [Array<RuboCop::AST::Node>] group The group to potentially save.
        # @return [void]
        def save_group_if_valid(groups, group)
          groups << group if group.size > 1
        end

        # Finalize groups by adding any remaining valid group.
        #
        # @param [Array<Array<RuboCop::AST::Node>>] groups The groups.
        # @param [Array<RuboCop::AST::Node>] current_group The current group.
        # @return [Array<Array<RuboCop::AST::Node>>] The finalized groups.
        def finalize_groups(groups, current_group)
          save_group_if_valid(groups, current_group)
          groups
        end

        # Check if node is a local variable assignment.
        #
        # @param [RuboCop::AST::Node] node The node.
        # @return [Boolean]
        def local_variable_assignment?(node)
          node.lvasgn_type?
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

        # Create a source range between two positions.
        #
        # @param [Integer] start_pos The start position.
        # @param [Integer] end_pos The end position.
        # @return [Parser::Source::Range]
        def range_between(start_pos, end_pos)
          Parser::Source::Range.new(
            processed_source.buffer,
            start_pos,
            end_pos
          )
        end
      end
    end
  end
end
