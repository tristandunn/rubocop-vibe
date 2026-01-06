# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces that tests are not skipped or marked as pending.
      #
      # This cop encourages completing tests rather than leaving them
      # skipped or pending. If a test cannot be implemented, it should
      # be deleted rather than left as a placeholder.
      #
      # @example
      #   # bad - skip call
      #   it "does something" do
      #     skip "not implemented yet"
      #   end
      #
      #   # bad - pending call
      #   it "does something" do
      #     pending "waiting on feature"
      #   end
      #
      #   # bad - xit (skipped it)
      #   xit "does something" do
      #     expect(true).to be true
      #   end
      #
      #   # bad - xdescribe/xcontext
      #   xdescribe "MyClass" do
      #     it "works" do
      #     end
      #   end
      #
      #   # good - implement the test
      #   it "does something" do
      #     expect(result).to eq(expected)
      #   end
      class NoSkippedTests < Base
        include SpecFileHelper

        MSG_SKIP    = "Do not skip tests. Implement or delete the test."
        MSG_PENDING = "Do not mark tests as pending. Implement or delete the test."
        MSG_XMETHOD = "Do not use `%<method>s`. Implement or delete the test."

        SKIP_METHODS    = %i(skip).freeze
        PENDING_METHODS = %i(pending).freeze
        X_METHODS       = %i(xit xspecify xexample xscenario xdescribe xcontext xfeature).freeze

        # @!method skip_call?(node)
        #   Check if node is a skip call.
        def_node_matcher :skip_call?, <<~PATTERN
          (send nil? {:skip} ...)
        PATTERN

        # @!method pending_call?(node)
        #   Check if node is a pending call.
        def_node_matcher :pending_call?, <<~PATTERN
          (send nil? {:pending} ...)
        PATTERN

        # @!method x_method_call?(node)
        #   Check if node is an x-prefixed test method.
        def_node_matcher :x_method_call?, <<~PATTERN
          (send nil? ${:xit :xspecify :xexample :xscenario :xdescribe :xcontext :xfeature} ...)
        PATTERN

        # Check for skip calls in spec files.
        #
        # @param [RuboCop::AST::Node] node The send node.
        # @return [void]
        def on_send(node)
          if spec_file?
            check_skip(node)
            check_pending(node)
            check_x_method(node)
          end
        end
        alias on_csend on_send

        private

        # Check for skip method calls.
        #
        # @param [RuboCop::AST::Node] node The send node.
        # @return [void]
        def check_skip(node)
          if skip_call?(node)
            add_offense(node, message: MSG_SKIP)
          end
        end

        # Check for pending method calls.
        #
        # @param [RuboCop::AST::Node] node The send node.
        # @return [void]
        def check_pending(node)
          if pending_call?(node)
            add_offense(node, message: MSG_PENDING)
          end
        end

        # Check for x-prefixed test method calls.
        #
        # @param [RuboCop::AST::Node] node The send node.
        # @return [void]
        def check_x_method(node)
          method_name = x_method_call?(node)
          if method_name
            add_offense(node, message: format(MSG_XMETHOD, method: method_name))
          end
        end
      end
    end
  end
end
