# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Shared helper methods for consecutive alignment cops.
      #
      # Provides common functionality for grouping consecutive statements
      # and creating source ranges for autocorrection.
      module AlignmentHelpers
        private

        # Extract statements from a body node.
        #
        # @param [RuboCop::AST::Node] body The body node.
        # @return [Array<RuboCop::AST::Node>]
        def extract_statements(body)
          body.begin_type? ? body.children : [body]
        end

        # Group consecutive statements based on a predicate.
        #
        # Iterates through statements and groups consecutive ones where the block
        # returns true. Groups are broken by non-matching statements or blank lines.
        #
        # @param [Array<RuboCop::AST::Node>] statements The statements.
        # @yield [RuboCop::AST::Node] Block to determine if statement matches criteria.
        # @return [Array<Array<RuboCop::AST::Node>>] Groups of consecutive matching statements.
        def group_consecutive_statements(statements, &)
          matching_with_indices = find_matching_statements(statements, &)
          group_by_consecutive_lines(matching_with_indices, statements)
        end

        # Find statements matching the predicate with their indices.
        #
        # @param [Array<RuboCop::AST::Node>] statements The statements.
        # @return [Array<Array>] Array of [index, statement] pairs.
        def find_matching_statements(statements)
          statements.each_with_index.filter_map do |stmt, idx|
            [idx, stmt] if yield(stmt)
          end
        end

        # Group matched statements that are on consecutive lines.
        #
        # @param [Array<Array>] matches Array of [index, statement] pairs.
        # @param [Array<RuboCop::AST::Node>] statements Original statements for line lookups.
        # @return [Array<Array<RuboCop::AST::Node>>] Groups with 2+ consecutive statements.
        def group_by_consecutive_lines(matches, statements)
          matches
            .chunk_while { |a, b| consecutive?(a, b, statements) }
            .filter_map { |group| group.map(&:last) if group.size > 1 }
        end

        # Check if two matched statements are consecutive (no gaps).
        #
        # @param [Array] first First [index, statement] pair.
        # @param [Array] second Second [index, statement] pair.
        # @param [Array<RuboCop::AST::Node>] statements Original statements.
        # @return [Boolean]
        def consecutive?(first, second, statements)
          idx_a, stmt_a = first
          idx_b, = second
          idx_b == idx_a + 1 && no_blank_line_between?(stmt_a, statements[idx_b])
        end

        # Check if there's no blank line between two statements.
        #
        # @param [RuboCop::AST::Node] stmt_a First statement.
        # @param [RuboCop::AST::Node] stmt_b Second statement.
        # @return [Boolean]
        def no_blank_line_between?(stmt_a, stmt_b)
          stmt_b.loc.line - stmt_a.loc.last_line <= 1
        end

        # Create a source range between two positions.
        #
        # @param [Integer] start_pos The start position.
        # @param [Integer] end_pos The end position.
        # @return [Parser::Source::Range]
        def range_between(start_pos, end_pos)
          Parser::Source::Range.new(processed_source.buffer, start_pos, end_pos)
        end
      end
    end
  end
end
