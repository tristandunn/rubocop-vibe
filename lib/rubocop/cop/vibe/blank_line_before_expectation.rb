# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces a blank line before expectation calls when there's setup code above.
      #
      # @example
      #   # bad
      #   it "processes the record" do
      #     record.process
      #     expect(record).to be_processed
      #   end
      #
      #   # good
      #   it "processes the record" do
      #     record.process
      #
      #     expect(record).to be_processed
      #   end
      #
      #   # good - no setup code above
      #   it "is valid" do
      #     expect(record).to be_valid
      #   end
      class BlankLineBeforeExpectation < Base
        extend AutoCorrector
        include SpecFileHelper

        MSG = "Add a blank line before expectation when there is setup code above."

        # @!method example_block?(node)
        #   Check if block is an example block (it, specify, scenario).
        def_node_matcher :example_block?, <<~PATTERN
          (block (send nil? {:it :specify :scenario} ...) ...)
        PATTERN

        # @!method expect_call?(node)
        #   Check if node is an expect call.
        def_node_matcher :expect_call?, <<~PATTERN
          (send nil? :expect ...)
        PATTERN

        # Check block nodes for expect calls in example blocks.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [void]
        def on_block(node)
          return unless processable_block?(node)

          check_statements(extract_statements(node.body))
        end
        alias on_numblock on_block

        private

        # Check if the block should be processed.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [Boolean]
        def processable_block?(node)
          spec_file? && example_block?(node) && node.body
        end

        # Extract statements from the block body.
        #
        # @param [RuboCop::AST::Node] body The block body.
        # @return [Array<RuboCop::AST::Node>]
        def extract_statements(body)
          body.begin_type? ? body.children : [body]
        end

        # Check statements for missing blank lines before expectations.
        #
        # @param [Array<RuboCop::AST::Node>] statements The statements to check.
        # @return [void]
        def check_statements(statements)
          statements.each_with_index do |statement, index|
            next if index.zero?

            check_statement_pair(statements[index - 1], statement)
          end
        end

        # Check a pair of statements for missing blank line.
        #
        # @param [RuboCop::AST::Node] previous_statement The previous statement.
        # @param [RuboCop::AST::Node] current_statement The current statement.
        # @return [void]
        def check_statement_pair(previous_statement, current_statement)
          expect_node = find_expect_node(current_statement)
          return unless expect_node
          return if blank_line_between?(previous_statement, current_statement)
          return if find_expect_node(previous_statement)

          register_offense(expect_node, previous_statement)
        end

        # Register an offense for missing blank line.
        #
        # @param [RuboCop::AST::Node] expect_node The expect node.
        # @param [RuboCop::AST::Node] previous_statement The previous statement.
        # @return [void]
        def register_offense(expect_node, previous_statement)
          add_offense(expect_node.loc.selector) do |corrector|
            corrector.insert_after(previous_statement, "\n")
          end
        end

        # Find the expect node within a statement.
        #
        # Searches the node and its descendants for expect calls.
        # Only searches within the statement's method chain, not into
        # nested blocks like those passed to other methods.
        #
        # @param [RuboCop::AST::Node] node The statement node.
        # @return [RuboCop::AST::Node] The expect node if found.
        # @return [nil] When no expect call is found.
        def find_expect_node(node)
          return unless node.send_type?

          # Check if this node itself is an expect call
          return node if expect_call?(node)

          # Search descendants for expect calls
          # This includes expect { ... } which has a block attached
          node.each_descendant(:send).find { |send_node| expect_call?(send_node) }
        end

        # Check if there's a blank line between two statements.
        #
        # @param [RuboCop::AST::Node] previous_node The previous statement.
        # @param [RuboCop::AST::Node] current_node The current statement.
        # @return [Boolean]
        def blank_line_between?(previous_node, current_node)
          current_node.loc.line - previous_node.loc.last_line > 1
        end
      end
    end
  end
end
