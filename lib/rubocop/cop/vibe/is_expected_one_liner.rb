# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces that `is_expected` is only used in one-liner `it { }` blocks.
      #
      # @example
      #   # bad
      #   it "returns true" do
      #     is_expected.to be(true)
      #   end
      #
      #   # good
      #   it { is_expected.to be(true) }
      #
      #   # good - expect with description is allowed
      #   it "returns the user" do
      #     expect(result).to eq(user)
      #   end
      class IsExpectedOneLiner < Base
        extend AutoCorrector
        include SpecFileHelper

        MSG = "Use one-liner `it { is_expected.to ... }` syntax when using `is_expected`."

        # @!method is_expected_call?(node)
        #   Check if node is an is_expected call.
        def_node_matcher :is_expected_call?, <<~PATTERN
          (send nil? :is_expected)
        PATTERN

        # @!method example_block_with_description?(node)
        #   Check if block is an example block with a description.
        def_node_matcher :example_block_with_description?, <<~PATTERN
          (block (send nil? {:it :specify} (str _) ...) ...)
        PATTERN

        # Check send nodes for is_expected calls inside described blocks.
        #
        # @param [RuboCop::AST::Node] node The send node.
        # @return [void]
        def on_send(node)
          return unless spec_file?
          return unless is_expected_call?(node)

          example_block = find_example_block(node)
          return unless example_block
          return unless example_block_with_description?(example_block)

          add_offense(example_block.send_node) do |corrector|
            autocorrect(corrector, example_block)
          end
        end
        alias on_csend on_send

        private

        # Find the enclosing example block for a node.
        #
        # @param [RuboCop::AST::Node] node The node to search from.
        # @return [RuboCop::AST::Node]
        # @return [nil] When no example block is found.
        def find_example_block(node)
          node.each_ancestor(:block).find do |ancestor|
            example_block?(ancestor)
          end
        end

        # Check if a block is an example block (it or specify).
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [Boolean]
        def example_block?(node)
          return false unless node.block_type?

          send_node = node.send_node
          send_node.method?(:it) || send_node.method?(:specify)
        end

        # Autocorrect the offense by converting to one-liner syntax.
        #
        # @param [RuboCop::Cop::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] node The block node.
        # @return [void]
        def autocorrect(corrector, node)
          return unless node.body

          expectation_source = node.body.source

          # Skip autocorrect for multi-line expectations
          return if expectation_source.include?("\n")

          corrector.replace(node, "it { #{expectation_source} }")
        end
      end
    end
  end
end
