# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces that `expect` is not nested inside another `expect` block.
      #
      # Nesting an `expect` inside an `expect { ... }` block is a workaround
      # for `RSpec/MultipleExpectations`. Split the example instead.
      #
      # @example
      #   # bad
      #   it "changes the count" do
      #     expect { perform }.to change { User.count }.by(1)
      #     expect { expect(user).to be_valid }.not_to raise_error
      #   end
      #
      #   # good
      #   it "changes the count" do
      #     expect { perform }.to change { User.count }.by(1)
      #   end
      #
      #   it "is valid" do
      #     expect(user).to be_valid
      #   end
      class NoNestedExpect < Base
        include SpecFileHelper

        MSG = "Do not nest `expect` inside another `expect` block."

        # Check for expect calls nested inside an expect block.
        #
        # @param [RuboCop::AST::Node] node The send node.
        # @return [void]
        def on_send(node)
          if spec_file? && expect_call?(node) && inside_expect_block?(node)
            add_offense(node)
          end
        end

        alias on_csend on_send

        private

        # Check if the node is a receiverless expect call.
        #
        # @param [RuboCop::AST::Node] node The node to check.
        # @return [Boolean]
        def expect_call?(node)
          node.receiver.nil? && node.method?(:expect)
        end

        # Check if the node is inside the block of an expect call.
        #
        # @param [RuboCop::AST::Node] node The node to check.
        # @return [Boolean]
        def inside_expect_block?(node)
          node.each_ancestor(:block).any? do |block|
            !block.send_node.equal?(node) && expect_call?(block.send_node)
          end
        end
      end
    end
  end
end
