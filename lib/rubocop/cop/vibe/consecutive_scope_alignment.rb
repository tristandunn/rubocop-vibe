# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces alignment of consecutive `scope` declarations at the `->` arrow.
      #
      # Consecutive `scope` declarations (with no blank lines between) should align
      # their `->` arrows for better readability. Groups are broken by blank lines or
      # non-scope statements.
      #
      # @example
      #   # bad
      #   scope :between, ->(start, stop) { where(created_at: start..stop) }
      #   scope :for_website, ->(website_id) { where(website_id: website_id) }
      #
      #   # good
      #   scope :between,     ->(start, stop) { where(created_at: start..stop) }
      #   scope :for_website, ->(website_id)  { where(website_id: website_id) }
      #
      #   # good - blank line breaks the group
      #   scope :between,     ->(start, stop) { where(created_at: start..stop) }
      #
      #   scope :for_website, ->(website_id) { where(website_id: website_id) }
      class ConsecutiveScopeAlignment < Base
        extend AutoCorrector
        include AlignmentHelpers

        MSG = "Align consecutive scope declarations at the `->` arrow."

        # Check class nodes for scope alignment.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @return [void]
        def on_class(node)
          if node.body
            check_scopes_in_body(node.body)
          end
        end

        private

        # Get the source range of the `->` arrow in a scope declaration.
        #
        # @param [RuboCop::AST::Node] scope_node The scope send node.
        # @return [Parser::Source::Range]
        def arrow_range(scope_node)
          scope_node.arguments[1].send_node.loc.selector
        end

        # Auto-correct the alignment of a scope declaration.
        #
        # @param [RuboCop::AST::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] scope_node The scope send node.
        # @param [Integer] target_column The target column for alignment.
        # @return [void]
        def autocorrect_alignment(corrector, scope_node, target_column)
          arrow        = arrow_range(scope_node)
          comma_end    = scope_node.first_argument.source_range.end_pos + 1
          arrow_start  = arrow.begin_pos
          total_spaces = calculate_total_spaces(scope_node, target_column)

          corrector.replace(
            range_between(comma_end, arrow_start),
            " " * total_spaces
          )
        end

        # Calculate total spaces needed for alignment.
        #
        # @param [RuboCop::AST::Node] scope_node The scope send node.
        # @param [Integer] target_column The target column for alignment.
        # @return [Integer] The number of spaces (minimum 1).
        def calculate_total_spaces(scope_node, target_column)
          arrow          = arrow_range(scope_node)
          comma_end      = scope_node.first_argument.source_range.end_pos + 1
          current_column = arrow.column
          current_spaces = arrow.begin_pos - comma_end
          spaces_needed  = target_column - current_column

          [1, current_spaces + spaces_needed].max
        end

        # Check alignment for a group of scope declarations.
        #
        # @param [Array<RuboCop::AST::Node>] group The scope group.
        # @return [void]
        def check_group_alignment(group)
          columns       = group.map { |scope| arrow_range(scope).column }
          target_column = columns.max

          group.each do |scope|
            current_column = arrow_range(scope).column

            next if current_column == target_column

            add_offense(scope.first_argument) do |corrector|
              autocorrect_alignment(corrector, scope, target_column)
            end
          end
        end

        # Check scope declarations in a body node.
        #
        # @param [RuboCop::AST::Node] body The body node.
        # @return [void]
        def check_scopes_in_body(body)
          statements = extract_statements(body)

          return if statements.size < 2

          groups = group_consecutive_statements(statements) { |statement| scope_declaration?(statement) }

          groups.each { |group| check_group_alignment(group) }
        end

        # Check if a node is a scope declaration with a lambda.
        #
        # @param [RuboCop::AST::Node] node The node to check.
        # @return [Boolean]
        def scope_declaration?(node)
          return false unless node.send_type?
          return false unless node.method?(:scope)
          return false unless node.receiver.nil?
          return false unless node.arguments[1]&.block_type?

          node.arguments[1].method?(:lambda)
        end
      end
    end
  end
end
