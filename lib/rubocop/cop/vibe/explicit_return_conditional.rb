# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces using explicit `if`/`else`/`end` blocks instead of ternary operators
      # or trailing conditionals when they are the return value of a method.
      #
      # Ternary operators and trailing conditionals can be harder to read when used
      # as method return values. This cop enforces converting them to explicit
      # `if`/`else`/`end` blocks for better readability.
      #
      # @example
      #   # bad - ternary as return value
      #   def allow_origin
      #     origin = request.headers["Origin"]
      #     origin_allowed?(origin) ? origin : "*"
      #   end
      #
      #   # good - explicit if/else
      #   def allow_origin
      #     origin = request.headers["Origin"]
      #     if origin_allowed?(origin)
      #       origin
      #     else
      #       "*"
      #     end
      #   end
      #
      #   # bad - trailing conditional as return value
      #   def vary
      #     "Origin" if website.present?
      #   end
      #
      #   # good - explicit if block
      #   def vary
      #     if website.present?
      #       "Origin"
      #     end
      #   end
      #
      #   # good - ternary used in assignment (not as return value)
      #   def example
      #     result = condition ? "yes" : "no"
      #     process(result)
      #   end
      class ExplicitReturnConditional < Base
        extend AutoCorrector

        MSG_TERNARY  = "Use explicit `if`/`else`/`end` block instead of ternary operator for return value."
        MSG_MODIFIER = "Use explicit `if`/`end` block instead of trailing conditional for return value."

        # Check method definitions for conditional return values.
        #
        # @param [RuboCop::AST::Node] node The def node.
        # @return [void]
        def on_def(node)
          if node.body
            check_return_value(node.body)
          end
        end
        alias on_defs on_def

        private

        # Check if the return value is a conditional that should be explicit.
        #
        # @param [RuboCop::AST::Node] body The method body node.
        # @return [void]
        def check_return_value(body)
          return_node = find_return_node(body)
          return unless return_node.if_type?

          if return_node.ternary?
            register_ternary_offense(return_node)
          elsif return_node.modifier_form?
            register_modifier_offense(return_node)
          end
        end

        # Find the node that represents the return value.
        #
        # @param [RuboCop::AST::Node] body The method body node.
        # @return [RuboCop::AST::Node, nil]
        def find_return_node(body)
          if body.begin_type?
            body.children.last
          else
            body
          end
        end

        # Register offense for ternary operator.
        #
        # @param [RuboCop::AST::Node] node The ternary node.
        # @return [void]
        def register_ternary_offense(node)
          add_offense(node, message: MSG_TERNARY) do |corrector|
            autocorrect_ternary(corrector, node)
          end
        end

        # Register offense for modifier conditional.
        #
        # @param [RuboCop::AST::Node] node The modifier if node.
        # @return [void]
        def register_modifier_offense(node)
          add_offense(node, message: MSG_MODIFIER) do |corrector|
            autocorrect_modifier(corrector, node)
          end
        end

        # Autocorrect ternary operator to if/else/end block.
        #
        # @param [RuboCop::Cop::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] node The ternary node.
        # @return [void]
        def autocorrect_ternary(corrector, node)
          corrector.replace(node, build_if_else_block(node))
        end

        # Autocorrect modifier conditional to if/end block.
        #
        # @param [RuboCop::Cop::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] node The modifier if node.
        # @return [void]
        def autocorrect_modifier(corrector, node)
          corrector.replace(node, build_if_block(node))
        end

        # Build if/else/end block replacement for ternary.
        #
        # @param [RuboCop::AST::Node] node The ternary node.
        # @return [String]
        def build_if_else_block(node)
          base_indent  = " " * node.loc.column
          inner_indent = "#{base_indent}  "

          [
            "if #{node.condition.source}",
            "#{inner_indent}#{node.if_branch.source}",
            "#{base_indent}else",
            "#{inner_indent}#{node.else_branch.source}",
            "#{base_indent}end"
          ].join("\n")
        end

        # Build if/end block replacement for modifier conditional.
        #
        # @param [RuboCop::AST::Node] node The modifier if node.
        # @return [String]
        def build_if_block(node)
          condition    = build_condition(node)
          base_indent  = " " * node.loc.column
          inner_indent = "#{base_indent}  "

          [
            "if #{condition}",
            "#{inner_indent}#{node.if_branch.source}",
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
            negate_condition(node.condition)
          else
            node.condition.source
          end
        end

        # Negate a condition, handling simple cases cleanly.
        #
        # @param [RuboCop::AST::Node] condition The condition node.
        # @return [String] The negated condition.
        def negate_condition(condition)
          if condition.send_type? && condition.method?(:!)
            condition.receiver.source
          else
            "!#{condition.source}"
          end
        end
      end
    end
  end
end
