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

          groups = group_consecutive_constants(statements)
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

        # Group consecutive constant assignments together.
        #
        # @param [Array<RuboCop::AST::Node>] statements The statements.
        # @return [Array<Array<RuboCop::AST::Node>>] Groups of consecutive constants.
        def group_consecutive_constants(statements)
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
          if constant_assignment?(statement)
            current_group = handle_constant(statement, current_group, previous_line, groups)
          else
            save_group_if_valid(groups, current_group)
            current_group = []
          end
          [current_group, statement.loc.last_line]
        end

        # Check if node is a single-line constant assignment.
        #
        # Only single-line constants are considered for alignment to avoid
        # conflicts with multi-line hash/array constants and Layout/ExtraSpacing.
        #
        # @param [RuboCop::AST::Node] node The node.
        # @return [Boolean]
        def constant_assignment?(node)
          node.casgn_type? && single_line?(node)
        end

        # Check if node is on a single line.
        #
        # @param [RuboCop::AST::Node] node The node.
        # @return [Boolean]
        def single_line?(node)
          node.single_line?
        end

        # Handle a constant assignment.
        #
        # @param [RuboCop::AST::Node] statement The constant assignment.
        # @param [Array<RuboCop::AST::Node>] current_group The current group.
        # @param [Integer, nil] previous_line The previous line number.
        # @param [Array<Array<RuboCop::AST::Node>>] groups The groups.
        # @return [Array<RuboCop::AST::Node>] The updated current group.
        def handle_constant(statement, current_group, previous_line, groups)
          if previous_line && statement.loc.line - previous_line > 1
            save_group_if_valid(groups, current_group)
            current_group = []
          end
          current_group << statement
          current_group
        end

        # Save group if it has multiple constant assignments.
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
