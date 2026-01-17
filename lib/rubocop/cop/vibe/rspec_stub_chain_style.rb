# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces that RSpec stub chains with `.with` or `.and_return` put each
      # chained method on its own line when the line exceeds the max line length.
      #
      # This improves readability by keeping each part of the stub configuration
      # on its own line rather than creating long horizontal lines.
      #
      # The max line length is read from the `Layout/LineLength` cop configuration.
      #
      # @example
      #   # bad (when line exceeds max length)
      #   allow(Foo).to receive(:bar).with(very_long_argument_name).and_return(result)
      #
      #   # good (split when line is too long)
      #   allow(Foo).to receive(:bar)
      #     .with(very_long_argument_name)
      #     .and_return(result)
      #
      #   # good - short stubs can stay on one line
      #   allow(Foo).to receive(:bar).with(arg).and_return(result)
      #
      #   # good - simple stubs without .with or .and_return are fine on one line
      #   allow(Foo).to receive(:bar)
      #
      #   # good - .and_return directly after receive is allowed
      #   allow(Foo).to receive(:bar).and_return(result)
      class RspecStubChainStyle < Base
        extend AutoCorrector
        include SpecFileHelper

        MSG = "Put each chained stub method on its own line when line is too long."

        CHAIN_METHODS = %i(
          with
          and_return
          and_raise
          and_throw
          and_yield
          and_call_original
          and_wrap_original
          once
          twice
          thrice
          exactly
          at_least
          at_most
          ordered
        ).freeze

        RECEIVE_METHODS = %i(receive receive_message_chain receive_messages have_received).freeze

        # @!method allow_to_receive?(node)
        #   Check if node is an allow/expect.to call with a receive chain argument.
        def_node_matcher :allow_to_receive?, <<~PATTERN
          (send
            (send nil? {:allow :expect :allow_any_instance_of :expect_any_instance_of} ...)
            :to
            $send)
        PATTERN

        # Check send nodes for stub chains that need line breaks.
        #
        # @param [RuboCop::AST::Node] node The send node.
        # @return [void]
        def on_send(node)
          if spec_file?
            allow_to_receive?(node) do |receive_chain|
              check_receive_chain(node, receive_chain)
            end
          end
        end
        alias on_csend on_send

        private

        # Check the receive chain for methods that should be on separate lines.
        #
        # @param [RuboCop::AST::Node] to_node The .to node.
        # @param [RuboCop::AST::Node] receive_chain The receive chain argument.
        # @return [void]
        def check_receive_chain(to_node, receive_chain)
          chain         = extract_chain(receive_chain)
          receive_index = find_receive_index(chain)

          return unless receive_index
          return unless chain_has_with?(chain)
          return unless line_exceeds_max_length?(to_node)

          methods = chain[(receive_index + 1)..]

          check_methods_alignment(to_node, chain[receive_index], methods)
        end

        # Check if the line containing the node exceeds the max line length.
        #
        # @param [RuboCop::AST::Node] node The node to check.
        # @return [Boolean]
        def line_exceeds_max_length?(node)
          line_number = node.loc.line
          line        = processed_source.lines[line_number - 1]

          line.length > max_line_length
        end

        # Get the configured max line length from Layout/LineLength.
        #
        # @return [Integer]
        def max_line_length
          config.for_cop("Layout/LineLength")["Max"] || 120
        end

        # Extract the method chain from a node.
        #
        # @param [RuboCop::AST::Node] node The send node.
        # @return [Array<RuboCop::AST::Node>]
        def extract_chain(node)
          chain   = []
          current = node

          while current&.send_type?
            chain.unshift(current)
            current = current.receiver
          end

          chain
        end

        # Find the index of the receive method in the chain.
        #
        # @param [Array<RuboCop::AST::Node>] chain The method chain.
        # @return [Integer, nil]
        def find_receive_index(chain)
          chain.index { |n| RECEIVE_METHODS.include?(n.method_name) }
        end

        # Check if the chain includes a .with call.
        #
        # @param [Array<RuboCop::AST::Node>] chain The method chain.
        # @return [Boolean]
        def chain_has_with?(chain)
          chain.any? { |n| n.method?(:with) }
        end

        # Check alignment of methods after receive.
        #
        # @param [RuboCop::AST::Node] to_node The .to node.
        # @param [RuboCop::AST::Node] receive_node The receive node.
        # @param [Array<RuboCop::AST::Node>] methods The methods to check.
        # @return [void]
        def check_methods_alignment(to_node, receive_node, methods)
          previous_node = receive_node
          is_first      = true

          methods.each do |method_node|
            if should_flag?(previous_node, method_node, is_first) && chainable_method?(method_node)
              register_offense(method_node, to_node)
            end
            previous_node = method_node
            is_first      = false
          end
        end

        # Check if the method should be flagged.
        #
        # @param [RuboCop::AST::Node] previous_node The previous node.
        # @param [RuboCop::AST::Node] method_node The method node.
        # @param [Boolean] is_first Whether this is the first method after receive.
        # @return [Boolean]
        def should_flag?(previous_node, method_node, is_first)
          reference_line = is_first ? previous_node.loc.last_line : previous_node.loc.selector.line

          reference_line == method_node.loc.selector.line
        end

        # Check if the method is one we care about for chaining.
        #
        # @param [RuboCop::AST::Node] node The method node.
        # @return [Boolean]
        def chainable_method?(node)
          CHAIN_METHODS.include?(node.method_name)
        end

        # Register an offense for a method that should be on its own line.
        #
        # @param [RuboCop::AST::Node] method_node The method node.
        # @param [RuboCop::AST::Node] previous_node The previous node in chain.
        # @return [void]
        def register_offense(method_node, previous_node)
          add_offense(method_node.loc.selector) do |corrector|
            autocorrect_chain(corrector, method_node, previous_node)
          end
        end

        # Auto-correct by inserting a newline before the method.
        #
        # @param [RuboCop::Cop::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] method_node The method to move.
        # @param [RuboCop::AST::Node] to_node The .to node for indentation.
        # @return [void]
        def autocorrect_chain(corrector, method_node, to_node)
          dot_range         = method_node.loc.dot
          indentation       = calculate_indentation(to_node)
          replacement_start = find_replacement_start(method_node)

          corrector.replace(
            range_between(replacement_start, dot_range.begin_pos),
            "\n#{indentation}"
          )
        end

        # Find the starting position for the replacement.
        #
        # @param [RuboCop::AST::Node] method_node The method node.
        # @return [Integer]
        def find_replacement_start(method_node)
          method_node.receiver.source_range.end_pos
        end

        # Calculate the indentation for the new line.
        #
        # @param [RuboCop::AST::Node] node The node to base indentation on.
        # @return [String]
        def calculate_indentation(node)
          base_column = find_chain_start_column(node)

          " " * (base_column + 2)
        end

        # Find the starting column of the chain.
        #
        # @param [RuboCop::AST::Node] node A node in the chain.
        # @return [Integer]
        def find_chain_start_column(node)
          current = node

          current = current.receiver while current.receiver&.send_type?

          current.loc.column
        end

        # Create a source range between two positions.
        #
        # @param [Integer] start_pos The start position.
        # @param [Integer] end_pos The end position.
        # @return [Parser::Source::Range]
        def range_between(start_pos, end_pos)
          Parser::Source::Range.new(
            processed_source.buffer,
            start_pos,
            end_pos
          )
        end
      end
    end
  end
end
