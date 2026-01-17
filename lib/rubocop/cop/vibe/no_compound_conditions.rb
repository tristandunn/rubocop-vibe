# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces extracting compound boolean conditions into named methods.
      #
      # When a conditional has multiple boolean expressions joined by `&&` or
      # `||`, the intent becomes unclear. Extracting to a descriptively-named
      # method documents the business logic.
      #
      # This cop does NOT flag compound conditions that are:
      # - The implied return value of a method (the extraction target)
      #
      # This cop DOES flag compound conditions that are:
      # - In if/unless/while/until/when/ternary conditions
      # - Inside an explicit return statement
      #
      # @example
      #   # bad - multiple conditions obscure intent
      #   if user.active? && user.verified?
      #     grant_access
      #   end
      #
      #   # bad - mixing operators
      #   return if admin? || moderator?
      #
      #   # bad - negation wrapping compound
      #   if !(order.paid? && order.shipped?)
      #     send_reminder
      #   end
      #
      #   # bad - explicit return with compound
      #   def can_participate?
      #     return admin? || moderator? if override?
      #     check_other_conditions
      #   end
      #
      #   # good - extracted to named method
      #   if user.can_participate?
      #     grant_access
      #   end
      #
      #   # good - compound as implied method return value (this is the extraction)
      #   def can_participate?
      #     user.active? && user.verified?
      #   end
      class NoCompoundConditions < Base
        MSG = "Extract compound conditions into a named method."

        # Check and/or nodes for conditional context.
        #
        # @param [RuboCop::AST::Node] node The and/or node.
        # @return [void]
        def on_and(node)
          check_compound(node)
        end
        alias on_or on_and

        private

        # Check if a compound condition should be flagged.
        #
        # @param [RuboCop::AST::Node] node The and/or node.
        # @return [void]
        def check_compound(node)
          if inside_return_statement?(node) || in_conditional_position?(node)
            add_offense(node)
          end
        end

        # Check if node is in a conditional position (if/unless/while/until/when condition).
        #
        # @param [RuboCop::AST::Node] node The and/or node.
        # @return [Boolean]
        def in_conditional_position?(node)
          ancestor = conditional_ancestor(node)

          if ancestor
            condition_of_ancestor?(node, ancestor)
          else
            false
          end
        end

        # Find the nearest conditional ancestor (if/while/until/when).
        #
        # @param [RuboCop::AST::Node] node The node.
        # @return [RuboCop::AST::Node, nil]
        def conditional_ancestor(node)
          node.each_ancestor.find { |a| a.type?(:if, :while, :until, :when) }
        end

        # Check if node is (part of) the condition of the ancestor.
        #
        # @param [RuboCop::AST::Node] node The and/or node.
        # @param [RuboCop::AST::Node] ancestor The if/while/until/when ancestor.
        # @return [Boolean]
        def condition_of_ancestor?(node, ancestor)
          condition = condition_node(ancestor)

          node_within_condition?(node, condition)
        end

        # Extract the condition node from a conditional ancestor.
        #
        # @param [RuboCop::AST::Node] ancestor The conditional ancestor.
        # @return [RuboCop::AST::Node]
        def condition_node(ancestor)
          if ancestor.type?(:if, :while, :until)
            ancestor.condition
          else
            ancestor
          end
        end

        # Check if node is within the condition subtree.
        #
        # @param [RuboCop::AST::Node] node The node to find.
        # @param [RuboCop::AST::Node] condition The condition root.
        # @return [Boolean]
        def node_within_condition?(node, condition)
          return true if condition == node

          condition.each_descendant.any?(node)
        end

        # Check if node is inside a return statement.
        #
        # @param [RuboCop::AST::Node] node The node.
        # @return [Boolean]
        def inside_return_statement?(node)
          node.each_ancestor.any?(&:return_type?)
        end
      end
    end
  end
end
