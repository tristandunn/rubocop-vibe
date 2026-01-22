# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces using `do...end` syntax instead of braces for RSpec `before` blocks.
      #
      # @example
      #   # bad
      #   before { setup_data }
      #
      #   # bad
      #   before(:each) { setup_data }
      #
      #   # good
      #   before do
      #     setup_data
      #   end
      #
      #   # good
      #   before(:each) do
      #     setup_data
      #   end
      class RspecBeforeBlockStyle < Base
        extend AutoCorrector
        include SpecFileHelper

        MSG = "Use `do...end` block syntax instead of braces for `%<method>s` blocks."

        HOOK_METHODS = %i(before after around).freeze

        # Check block nodes for brace-style hooks.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [void]
        def on_block(node)
          return unless spec_file?
          return unless hook_block?(node)
          return unless node.braces?

          method_name = node.method_name

          add_offense(node.loc.begin, message: format(MSG, method: method_name)) do |corrector|
            autocorrect(corrector, node)
          end
        end
        alias on_numblock on_block

        private

        # Check if the block is a hook block (before, after, around).
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [Boolean]
        def hook_block?(node)
          send_node = node.send_node

          send_node.receiver.nil? && HOOK_METHODS.include?(send_node.method_name)
        end

        # Autocorrect the offense by converting braces to do...end.
        #
        # @param [RuboCop::Cop::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] node The block node.
        # @return [void]
        def autocorrect(corrector, node)
          base_indent = " " * node.loc.column
          replacement = build_replacement(node, base_indent)

          corrector.replace(block_range(node), replacement)
        end

        # Build the replacement string for the block.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @param [String] base_indent The base indentation.
        # @return [String]
        def build_replacement(node, base_indent)
          parts = ["do"]

          if node.arguments.source_range
            parts << " #{node.arguments.source}"
          end

          if node.body
            body_source = format_body(node.body, "#{base_indent}  ")
            parts << "\n#{body_source}"
          end

          parts << "\n#{base_indent}end"

          parts.join
        end

        # Get the range from the opening brace to the closing brace.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [Parser::Source::Range]
        def block_range(node)
          node.loc.begin.join(node.loc.end)
        end

        # Format the body with proper indentation.
        #
        # @param [RuboCop::AST::Node] body The body node.
        # @param [String] indent The indentation string.
        # @return [String]
        def format_body(body, indent)
          body.source.lines.map { |line| "#{indent}#{line.strip}" }.join("\n")
        end
      end
    end
  end
end
