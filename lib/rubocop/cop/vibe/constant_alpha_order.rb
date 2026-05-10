# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces alphabetical ordering of consecutive constant declarations by name.
      #
      # Consecutive constant declarations (with no blank lines between) should be
      # alphabetically ordered by constant name for better readability and
      # easier scanning. Groups are broken by blank lines or non-constant statements.
      #
      # @example
      #   # bad
      #   class MyClass
      #     ZEBRA = 1
      #     ALPHA = 2
      #   end
      #
      #   # good
      #   class MyClass
      #     ALPHA = 2
      #     ZEBRA = 1
      #   end
      #
      #   # good - blank line breaks the group
      #   class MyClass
      #     ZEBRA = 1
      #
      #     ALPHA = 2
      #   end
      class ConstantAlphaOrder < Base
        extend AutoCorrector
        include AlignmentHelpers

        MSG = "Order constants alphabetically by name."

        # Check block nodes for constant ordering.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [void]
        def on_block(node)
          if node.body
            check_constants_in_body(node.body)
          end
        end
        alias on_itblock on_block
        alias on_numblock on_block

        # Check class nodes for constant ordering.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @return [void]
        def on_class(node)
          if node.body
            check_constants_in_body(node.body)
          end
        end

        # Check module nodes for constant ordering.
        #
        # @param [RuboCop::AST::Node] node The module node.
        # @return [void]
        def on_module(node)
          if node.body
            check_constants_in_body(node.body)
          end
        end

        private

        # Check if constant declarations are alphabetically ordered.
        #
        # @param [Array<RuboCop::AST::Node>] group The constants group.
        # @return [Boolean]
        def alphabetically_ordered?(group)
          names = group.map { |constant| constant.name.to_s }

          names == names.sort
        end

        # Auto-correct by reordering constant declarations.
        #
        # @param [RuboCop::AST::Corrector] corrector The corrector.
        # @param [Array<RuboCop::AST::Node>] group The constants group.
        # @return [void]
        def autocorrect(corrector, group)
          sorted = group.sort_by { |constant| constant.name.to_s }

          group.each_with_index do |constant, index|
            sorted_constant = sorted[index]

            next if constant == sorted_constant

            corrector.replace(constant, sorted_constant.source)
          end
        end

        # Check constant declarations in a body node.
        #
        # @param [RuboCop::AST::Node] body The body node.
        # @return [void]
        def check_constants_in_body(body)
          statements = extract_statements(body)

          return if statements.size < 2

          groups = group_consecutive_statements(statements, &:casgn_type?)

          groups.each { |group| check_group_order(group) }
        end

        # Check ordering for a group of constant declarations.
        #
        # @param [Array<RuboCop::AST::Node>] group The constants group.
        # @return [void]
        def check_group_order(group)
          return if alphabetically_ordered?(group)

          violations = find_ordering_violations(group)

          violations.each do |constant|
            add_offense(constant) do |corrector|
              autocorrect(corrector, group)
            end
          end
        end

        # Find constant declarations that violate ordering.
        #
        # @param [Array<RuboCop::AST::Node>] group The constants group.
        # @return [Array<RuboCop::AST::Node>] Constants that violate ordering.
        def find_ordering_violations(group)
          violations = []

          group.each_cons(2) do |current, following|
            violations << following if current.name.to_s > following.name.to_s
          end

          violations.uniq
        end
      end
    end
  end
end
