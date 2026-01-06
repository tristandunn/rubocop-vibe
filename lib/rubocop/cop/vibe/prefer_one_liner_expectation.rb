# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces one-liner syntax for simple RSpec expectations.
      #
      # @example
      #   # bad
      #   it "responds with ok" do
      #     expect(subject).to respond_with(:ok)
      #   end
      #
      #   # good
      #   it { is_expected.to respond_with(:ok) }
      #
      #   # good - multi-line allowed for change expectations
      #   it "creates a record" do
      #     expect { subject }.to change(Resource, :count).by(1)
      #   end
      #
      #   # good - multi-line allowed for setup
      #   it "processes the record" do
      #     record.process
      #
      #     expect(record).to be_processed
      #   end
      class PreferOneLinerExpectation < Base
        extend AutoCorrector

        MSG = "Use one-liner `it { is_expected.to }` syntax for simple expectations."
        SPEC_FILE_PATTERN = %r{spec/.*_spec\.rb}

        # Check block nodes for multi-line it blocks with simple expectations.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [void]
        def on_block(node)
          return unless processable_block?(node)
          return unless single_statement?(node.body)

          expectation = extract_expectation(node.body)
          return unless simple_expectation?(expectation)

          add_offense(node.send_node) do |corrector|
            autocorrect(corrector, node)
          end
        end
        alias on_numblock on_block

        private

        # Autocorrect the offense by converting to one-liner syntax.
        #
        # @param [RuboCop::Cop::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] node The block node.
        # @return [void]
        def autocorrect(corrector, node)
          expectation_source = node.body.source

          # Replace the entire block with one-liner syntax
          corrector.replace(node, "it { #{expectation_source} }")
        end

        # Check if the block should be processed.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [Boolean]
        def processable_block?(node)
          spec_file? && example_block_with_description?(node)
        end

        # Check if file is a spec file.
        #
        # @return [Boolean]
        def spec_file?
          processed_source.file_path.match?(SPEC_FILE_PATTERN)
        end

        # Check if block is an example block with a description.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [Boolean]
        def example_block_with_description?(node)
          return false unless node.block_type?
          return false unless %i(it specify).include?(node.method_name)

          # Has a description argument (not one-liner syntax)
          node.send_node.arguments?
        end

        # Check if the body contains only a single statement.
        #
        # @param [RuboCop::AST::Node] body The block body.
        # @return [Boolean]
        def single_statement?(body)
          return false unless body

          !body.begin_type?
        end

        # Extract the expectation node from the body.
        #
        # @param [RuboCop::AST::Node] body The block body.
        # @return [RuboCop::AST::Node]
        # @return [nil] When no expectation is found.
        def extract_expectation(body)
          return nil unless body.send_type?

          # Check if the body contains is_expected or expect
          find_expectation_in_chain(body)
        end

        # Find expectation node in method chain.
        #
        # @param [RuboCop::AST::Node] node The node to search.
        # @return [RuboCop::AST::Node]
        # @return [nil] When no expectation is found.
        def find_expectation_in_chain(node)
          # Traverse up the chain looking for expect or is_expected
          current = node
          while current&.send_type?
            return current if expectation_method?(current)

            current = current.receiver
          end

          nil
        end

        # Check if node is an expectation method call.
        #
        # @param [RuboCop::AST::Node] node The node to check.
        # @return [Boolean]
        def expectation_method?(node)
          return false unless node.send_type?

          node.method?(:expect) || node.method?(:is_expected)
        end

        # Check if the expectation is simple (not a block expectation).
        #
        # Simple expectations use expect(value) or is_expected.
        # Block expectations use expect { ... } and are not simple.
        #
        # @param [RuboCop::AST::Node] node The expectation node.
        # @return [Boolean] True if simple expectation, false if block expectation.
        def simple_expectation?(node)
          return false unless node

          # is_expected is always simple
          return true if node.method?(:is_expected)

          # For expect, check if it has a block (expect { ... })
          node.method?(:expect) && !node.block_node
        end
      end
    end
  end
end
