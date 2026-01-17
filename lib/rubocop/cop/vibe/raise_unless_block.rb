# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces using `if/end` blocks instead of inline modifiers for `raise` statements.
      #
      # Inline `raise ... if/unless` statements can be harder to read because they
      # place the condition after the action. This cop enforces converting them
      # to `if/end` blocks for better readability.
      #
      # @example
      #   # bad - inline unless modifier
      #   raise ArgumentError, "Invalid column" unless COLUMNS.include?(column)
      #
      #   # good - if block with negated condition
      #   if !COLUMNS.include?(column)
      #     raise ArgumentError, "Invalid column"
      #   end
      #
      #   # bad - inline if modifier
      #   raise ArgumentError, "Invalid column" if column.nil?
      #
      #   # good - if block
      #   if column.nil?
      #     raise ArgumentError, "Invalid column"
      #   end
      #
      #   # good - raise without condition
      #   raise ArgumentError, "Invalid column"
      class RaiseUnlessBlock < Base
        extend AutoCorrector

        MSG = "Use `if/end` block instead of inline modifier for `raise`."

        # Check if nodes for raise with if/unless modifier.
        #
        # @param [RuboCop::AST::Node] node The if node.
        # @return [void]
        def on_if(node)
          return unless node.modifier_form?
          return unless raise_call?(node.body)

          add_offense(node) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        # Check if the node is a raise method call.
        #
        # @param [RuboCop::AST::Node] node The node to check.
        # @return [Boolean]
        def raise_call?(node)
          node.send_type? && node.method?(:raise)
        end

        # Autocorrect the offense by converting to if block.
        #
        # @param [RuboCop::Cop::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] node The if node.
        # @return [void]
        def autocorrect(corrector, node)
          replacement = build_replacement(node)

          corrector.replace(node, replacement)
        end

        # Build the replacement code for the raise statement.
        #
        # @param [RuboCop::AST::Node] node The if node.
        # @return [String] The replacement code.
        def build_replacement(node)
          condition    = build_condition(node)
          raise_source = node.body.source
          base_indent  = " " * node.loc.column
          inner_indent = "#{base_indent}  "

          [
            "if #{condition}",
            "#{inner_indent}#{raise_source}",
            "#{base_indent}end"
          ].join("\n")
        end

        # Build the condition for the if block.
        # For unless, negate the condition. For if, keep it as is.
        #
        # @param [RuboCop::AST::Node] node The if node.
        # @return [String] The condition source.
        def build_condition(node)
          if node.unless?
            "!#{node.condition.source}"
          else
            node.condition.source
          end
        end
      end
    end
  end
end
