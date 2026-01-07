# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces using positive `if` conditions instead of `unless` for guard clauses.
      #
      # Guard clauses with `unless` can be harder to read because they introduce
      # double negatives. This cop enforces converting guard clauses from negative
      # `unless` conditions to positive `if` conditions with the logic in a block.
      #
      # @example
      #   # bad - unless guard clause with implicit nil return
      #   def unless_example
      #     return unless valid?
      #
      #     4
      #   end
      #
      #   # good - positive if condition
      #   def unless_example_valid
      #     if valid?
      #       4
      #     end
      #   end
      #
      #   # bad - unless guard clause with explicit return value
      #   def unless_example
      #     return 32 unless valid?
      #
      #     4
      #   end
      #
      #   # good - positive if/else condition
      #   def unless_example_valid
      #     if valid?
      #       4
      #     else
      #       32
      #     end
      #   end
      #
      #   # good - regular if guard clauses are allowed
      #   def if_example
      #     return if valid?
      #
      #     4
      #   end
      class NoUnlessGuardClause < Base
        extend AutoCorrector

        MSG = "Use positive `if` condition instead of `unless` for guard clauses."

        # @!method unless_modifier?(node)
        #   Check if node is a statement with an unless modifier.
        def_node_matcher :unless_modifier?, <<~PATTERN
          (if $_ $_ nil?)
        PATTERN

        # Check if nodes for unless guard clauses.
        #
        # @param [RuboCop::AST::Node] node The if node.
        # @return [void]
        def on_if(node)
          return unless node.unless? && node.modifier_form? && guard_clause?(node)
          return if part_of_guard_clause_sequence?(node)
          return if would_create_nested_conditional?(node)

          add_offense(node) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        # Check if the unless statement is a guard clause (early return).
        #
        # @param [RuboCop::AST::Node] node The if node.
        # @return [Boolean]
        def guard_clause?(node)
          if node.body.return_type?
            parent = node.parent
            if parent.begin_type?
              following_statements?(parent, node)
            else
              false
            end
          else
            false
          end
        end

        # Check if there are statements after the node in the parent block.
        #
        # @param [RuboCop::AST::Node] parent The parent begin block.
        # @param [RuboCop::AST::Node] node The current node.
        # @return [Boolean]
        def following_statements?(parent, node)
          siblings   = parent.children
          node_index = siblings.index(node)
          siblings[(node_index + 1)..].any?
        end

        # Check if this unless guard clause is part of a sequence of guard clauses.
        # When there are multiple guard clauses together, they should stay at the same level.
        #
        # @param [RuboCop::AST::Node] node The if node.
        # @return [Boolean]
        def part_of_guard_clause_sequence?(node)
          siblings   = node.parent.children
          node_index = siblings.index(node)

          # Check for other guard clauses before this one.
          preceding_guards = siblings[0...node_index].any? { |sibling| any_guard_clause?(sibling) }

          # Check for other guard clauses after this one.
          following_guards = siblings[(node_index + 1)..].any? { |sibling| any_guard_clause?(sibling) }

          preceding_guards || following_guards
        end

        # Check if a node is any type of guard clause (if or unless).
        #
        # @param [RuboCop::AST::Node] node The node to check.
        # @return [Boolean]
        def any_guard_clause?(node)
          node.if_type? && node.modifier_form? && node.body.return_type?
        end

        # Check if transforming this guard clause would create nested conditionals.
        # If the remaining code is a conditional, we'd nest it inside our new if block.
        #
        # Note: This is only called after guard_clause? returns true, which means
        # there are statements after this node, so remaining will never be empty.
        #
        # @param [RuboCop::AST::Node] node The if node.
        # @return [Boolean]
        def would_create_nested_conditional?(node)
          siblings        = node.parent.children
          node_index      = siblings.index(node)
          first_statement = siblings[node_index + 1]

          first_statement.type?(:if, :case)
        end

        # Autocorrect the offense by converting to positive if condition.
        #
        # @param [RuboCop::Cop::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] node The if node.
        # @return [void]
        def autocorrect(corrector, node)
          replacement = build_replacement(node)
          range       = replacement_range(node)
          corrector.replace(range, replacement)
        end

        # Build the replacement code for the guard clause.
        #
        # @param [RuboCop::AST::Node] node The if node.
        # @return [String] The replacement code.
        def build_replacement(node)
          condition      = node.condition.source
          return_value   = extract_return_value(node.body)
          base_indent    = " " * node.loc.column
          inner_indent   = "#{base_indent}  "
          remaining_code = get_remaining_code(node)

          if return_value
            build_if_else_replacement(condition, remaining_code, return_value, base_indent, inner_indent)
          else
            build_if_replacement(condition, remaining_code, base_indent, inner_indent)
          end
        end

        # Build if/else replacement code.
        #
        # @param condition [String] The condition expression.
        # @param remaining_code [String] The remaining code to execute.
        # @param return_value [String] The return value for the else branch.
        # @param base_indent [String] The base indentation level.
        # @param inner_indent [String] The inner indentation level.
        # @return [String]
        def build_if_else_replacement(condition, remaining_code, return_value, base_indent, inner_indent)
          [
            "if #{condition}",
            indent_lines(remaining_code, inner_indent),
            "#{base_indent}else",
            indent_lines(return_value, inner_indent),
            "#{base_indent}end"
          ].join("\n")
        end

        # Build if replacement code.
        #
        # @param condition [String] The condition expression.
        # @param remaining_code [String] The remaining code to execute.
        # @param base_indent [String] The base indentation level.
        # @param inner_indent [String] The inner indentation level.
        # @return [String]
        def build_if_replacement(condition, remaining_code, base_indent, inner_indent)
          [
            "if #{condition}",
            indent_lines(remaining_code, inner_indent),
            "#{base_indent}end"
          ].join("\n")
        end

        # Get the code remaining after the guard clause.
        #
        # @param [RuboCop::AST::Node] node The if node.
        # @return [String] The remaining code.
        def get_remaining_code(node)
          siblings   = node.parent.children
          node_index = siblings.index(node)
          siblings[(node_index + 1)..].map(&:source).join("\n")
        end

        # Get the replacement range.
        #
        # @param [RuboCop::AST::Node] node The if node.
        # @return [Parser::Source::Range] The range to replace.
        def replacement_range(node)
          siblings  = node.parent.children
          start_pos = node.source_range.begin_pos
          end_pos   = siblings.last.source_range.end_pos
          Parser::Source::Range.new(node.source_range.source_buffer, start_pos, end_pos)
        end

        # Extract the return value from a return node.
        #
        # @param [RuboCop::AST::Node] node The return node.
        # @return [String, nil] The return value source or nil if no value.
        def extract_return_value(node)
          if node.children.any?
            node.children.first.source
          end
        end

        # Indent each line of code with the specified indentation.
        #
        # @param [String] code The code to indent.
        # @param [String] indentation The indentation string.
        # @return [String] The indented code.
        def indent_lines(code, indentation)
          code.lines.map { |line| "#{indentation}#{line}" }.join.chomp
        end
      end
    end
  end
end
