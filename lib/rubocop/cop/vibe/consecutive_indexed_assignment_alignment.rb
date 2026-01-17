# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces alignment of consecutive indexed assignments at the `=` operator.
      #
      # Consecutive indexed assignments (with no blank lines between) should align
      # their `=` operators for better readability. Groups are broken by blank lines.
      #
      # @example
      #   # bad
      #   response.headers["Cache-Control"] = "public, max-age=3600"
      #   response.headers["Content-Type"] = "application/javascript"
      #
      #   # good
      #   response.headers["Cache-Control"] = "public, max-age=3600"
      #   response.headers["Content-Type"]  = "application/javascript"
      #
      #   # good - blank line breaks the group
      #   response.headers["Cache-Control"] = "public, max-age=3600"
      #
      #   hash["key"] = "value"  # Separate group, not aligned
      class ConsecutiveIndexedAssignmentAlignment < Base
        extend AutoCorrector
        include AlignmentHelpers

        MSG = "Align consecutive indexed assignments at the = operator."

        # Check block nodes for indexed assignment alignment.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [void]
        def on_block(node)
          if node.body
            check_indexed_assignments_in_body(node.body)
          end
        end
        alias on_numblock on_block

        # Check method definitions for indexed assignment alignment.
        #
        # @param [RuboCop::AST::Node] node The def node.
        # @return [void]
        def on_def(node)
          if node.body
            check_indexed_assignments_in_body(node.body)
          end
        end
        alias on_defs on_def

        private

        # Check indexed assignments in a body node.
        #
        # @param [RuboCop::AST::Node] body The body node.
        # @return [void]
        def check_indexed_assignments_in_body(body)
          statements = extract_statements(body)

          return if statements.size < 2

          groups = group_consecutive_statements(statements) { |s| indexed_assignment?(s) }

          groups.each { |group| check_group_alignment(group) }
        end

        # Check if a node is an indexed assignment.
        #
        # @param [RuboCop::AST::Node] node The node to check.
        # @return [Boolean]
        def indexed_assignment?(node)
          node.send_type? && node.method?(:[]=)
        end

        # Check alignment for a group of indexed assignments.
        #
        # @param [Array<RuboCop::AST::Node>] group The assignment group.
        # @return [void]
        def check_group_alignment(group)
          columns       = group.map { |asgn| asgn.loc.operator.column }
          target_column = columns.max

          group.each do |asgn|
            current_column = asgn.loc.operator.column

            next if current_column == target_column

            add_offense(offense_location(asgn)) do |corrector|
              autocorrect_alignment(corrector, asgn, target_column)
            end
          end
        end

        # Get the location to highlight for the offense.
        #
        # @param [RuboCop::AST::Node] asgn The indexed assignment node.
        # @return [Parser::Source::Range]
        def offense_location(asgn)
          asgn.loc.selector
        end

        # Auto-correct the alignment of an indexed assignment.
        #
        # @param [RuboCop::AST::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] asgn The indexed assignment node.
        # @param [Integer] target_column The target column for alignment.
        # @return [void]
        def autocorrect_alignment(corrector, asgn, target_column)
          bracket_end    = closing_bracket_end_pos(asgn)
          operator_start = asgn.loc.operator.begin_pos
          total_spaces   = calculate_total_spaces(asgn, target_column, bracket_end, operator_start)

          corrector.replace(
            range_between(bracket_end, operator_start),
            " " * total_spaces
          )
        end

        # Get the position after the closing bracket.
        #
        # @param [RuboCop::AST::Node] asgn The indexed assignment node.
        # @return [Integer]
        def closing_bracket_end_pos(asgn)
          asgn.first_argument.source_range.end_pos + 1
        end

        # Calculate total spaces needed for alignment.
        #
        # @param [RuboCop::AST::Node] asgn The indexed assignment node.
        # @param [Integer] target_column The target column for alignment.
        # @param [Integer] bracket_end Position after the closing bracket.
        # @param [Integer] operator_start Position of the operator.
        # @return [Integer] The number of spaces (minimum 1).
        def calculate_total_spaces(asgn, target_column, bracket_end, operator_start)
          current_column = asgn.loc.operator.column
          current_spaces = operator_start - bracket_end
          spaces_needed  = target_column - current_column

          [1, current_spaces + spaces_needed].max
        end
      end
    end
  end
end
