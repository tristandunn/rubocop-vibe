# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces alphabetical ordering of consecutive `let` declarations.
      #
      # Consecutive `let` declarations (with no blank lines between) should be
      # alphabetically ordered by their symbol name for better readability and
      # easier scanning. Groups are broken by blank lines or non-let statements.
      #
      # @example
      #   # bad
      #   let(:subcategory) { create(:category, :subcategory) }
      #   let(:budget)      { subcategory.budget }
      #   let(:category)    { subcategory.parent }
      #
      #   # good
      #   let(:budget)      { subcategory.budget }
      #   let(:category)    { subcategory.parent }
      #   let(:subcategory) { create(:category, :subcategory) }
      #
      #   # good - blank line breaks the group
      #   let(:zebra) { create(:zebra) }
      #
      #   let(:apple) { create(:apple) }
      class LetOrder < Base
        extend AutoCorrector
        include SpecFileHelper
        include AlignmentHelpers

        MSG = "Order consecutive `let` declarations alphabetically."

        # @!method let_declaration?(node)
        #   Check if node is a let/let! declaration.
        def_node_matcher :let_declaration?, <<~PATTERN
          (block (send nil? {:let :let!} (sym _)) ...)
        PATTERN

        # Check describe/context blocks for let ordering.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [void]
        def on_block(node)
          return unless spec_file?
          return unless describe_or_context?(node)
          return unless node.body

          check_lets_in_body(node.body)
        end
        alias on_numblock on_block

        private

        # Check if block is a describe or context block.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [Boolean]
        def describe_or_context?(node)
          node.send_node && %i(describe context).include?(node.method_name)
        end

        # Check let declarations in a body node.
        #
        # @param [RuboCop::AST::Node] body The body node.
        # @return [void]
        def check_lets_in_body(body)
          statements = extract_statements(body)

          return if statements.size < 2

          groups = group_consecutive_statements(statements) { |s| let_declaration?(s) }

          groups.each { |group| check_group_order(group) }
        end

        # Check ordering for a group of let declarations.
        #
        # @param [Array<RuboCop::AST::Node>] group The let group.
        # @return [void]
        def check_group_order(group)
          return if alphabetically_ordered?(group)

          violations = find_ordering_violations(group)

          violations.each do |let|
            add_offense(let.send_node) do |corrector|
              autocorrect(corrector, group)
            end
          end
        end

        # Check if let declarations are alphabetically ordered.
        #
        # @param [Array<RuboCop::AST::Node>] group The let group.
        # @return [Boolean]
        def alphabetically_ordered?(group)
          names = group.map { |let| extract_let_name(let) }

          names == names.sort
        end

        # Extract the symbol name from a let declaration.
        #
        # @param [RuboCop::AST::Node] let The let block node.
        # @return [String]
        def extract_let_name(let)
          let.send_node.first_argument.value.to_s
        end

        # Find let declarations that violate ordering.
        #
        # @param [Array<RuboCop::AST::Node>] group The let group.
        # @return [Array<RuboCop::AST::Node>] Lets that violate ordering.
        def find_ordering_violations(group)
          violations = []

          group.each_cons(2) do |current, following|
            current_name   = extract_let_name(current)
            following_name = extract_let_name(following)

            violations << following if current_name > following_name
          end

          violations.uniq
        end

        # Auto-correct by reordering let declarations.
        #
        # @param [RuboCop::AST::Corrector] corrector The corrector.
        # @param [Array<RuboCop::AST::Node>] group The let group.
        # @return [void]
        def autocorrect(corrector, group)
          sorted = group.sort_by { |let| extract_let_name(let) }

          group.each_with_index do |let, index|
            sorted_let = sorted[index]

            next if let == sorted_let

            corrector.replace(let, sorted_let.source)
          end
        end
      end
    end
  end
end
