# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces one-liner syntax for simple RSpec expectations with subject.
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
      #   # good - descriptions allowed for non-subject expectations
      #   it "inherits from base class" do
      #     expect(described_class.superclass).to eq(BaseClass)
      #   end
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
        include SpecFileHelper

        MSG = "Use one-liner `it { is_expected.to }` syntax for simple expectations."

        # @!method example_block_with_description?(node)
        #   Check if block is an example block (it, specify) with a description.
        def_node_matcher :example_block_with_description?, <<~PATTERN
          (block (send nil? {:it :specify} _ ...) ...)
        PATTERN

        # @!method expectation_method?(node)
        #   Check if node is an expect or is_expected call.
        def_node_matcher :expectation_method?, <<~PATTERN
          (send nil? {:expect :is_expected} ...)
        PATTERN

        # Check block nodes for multi-line it blocks with simple expectations.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [void]
        def on_block(node)
          return unless processable_block?(node)
          return unless single_statement?(node.body)

          expectation = extract_expectation(node.body)

          return unless simple_expectation?(expectation)
          return if complex_expectation?(node)

          add_offense(node.send_node) do |corrector|
            autocorrect(corrector, node)
          end
        end
        alias on_numblock on_block

        private

        # Check if the expectation is too complex for one-liner conversion.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [Boolean]
        def complex_expectation?(node)
          expectation_source = node.body.source

          # Multi-line expectations are complex.
          return true if expectation_source.include?("\n")

          # Expectations with compound matchers (.and, .or) are complex.
          compound_matcher?(node.body)
        end

        # Check if the expectation uses compound matchers.
        #
        # @param [RuboCop::AST::Node] node The expectation node.
        # @return [Boolean]
        def compound_matcher?(node)
          node.each_descendant(:send).any? do |send_node|
            send_node.method?(:and) || send_node.method?(:or)
          end
        end

        # Autocorrect the offense by converting to one-liner syntax.
        #
        # @param [RuboCop::Cop::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] node The block node.
        # @return [void]
        def autocorrect(corrector, node)
          expectation_source = node.body.source

          corrector.replace(node, "it { #{expectation_source} }")
        end

        # Check if the block should be processed.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [Boolean]
        def processable_block?(node)
          spec_file? && example_block_with_description?(node)
        end

        # Check if the body contains only a single statement.
        #
        # @param [RuboCop::AST::Node] body The block body.
        # @return [Boolean]
        def single_statement?(body)
          if body
            !body.begin_type?
          else
            false
          end
        end

        # Extract the expectation node from the body.
        #
        # @param [RuboCop::AST::Node] body The block body.
        # @return [RuboCop::AST::Node]
        # @return [nil] When no expectation is found.
        def extract_expectation(body)
          if body.send_type?
            find_expectation_in_chain(body)
          end
        end

        # Find expectation node in method chain.
        #
        # @param [RuboCop::AST::Node] node The node to search.
        # @return [RuboCop::AST::Node]
        # @return [nil] When no expectation is found.
        def find_expectation_in_chain(node)
          # Traverse up the chain looking for expect or is_expected.
          current = node

          while current&.send_type?
            return current if expectation_method?(current)

            current = current.receiver
          end

          nil
        end

        # Check if the expectation is simple (not a block expectation).
        #
        # Simple expectations use expect(subject).
        # Block expectations use expect { ... } and are not simple.
        # is_expected is handled by IsExpectedOneLiner cop.
        # expect with non-subject receivers should keep descriptions.
        #
        # @param [RuboCop::AST::Node] node The expectation node.
        # @return [Boolean] True if simple expectation with subject, false otherwise.
        def simple_expectation?(node)
          return false unless node
          return false unless node.method?(:expect) && !node.block_node

          # Only enforce one-liners for expect(subject).
          # Other receivers (user.email, described_class, etc.) should keep descriptions.
          expect_subject?(node)
        end

        # Check if the expectation is using subject as the receiver.
        #
        # @param [RuboCop::AST::Node] node The expect node.
        # @return [Boolean]
        def expect_subject?(node)
          argument = node.first_argument

          return false unless argument
          return false unless argument.send_type?

          argument.method?(:subject)
        end
      end
    end
  end
end
