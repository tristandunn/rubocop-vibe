# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces that hash arguments in multiline method calls are on separate
      # lines and alphabetically ordered by key name.
      #
      # This cop applies to method calls where the closing parenthesis is on
      # its own line.
      #
      # Value alignment (table style) is handled separately by Layout/HashAlignment.
      #
      # @example
      #   # bad - multiple hash pairs on same line
      #   SomeService.call(
      #     website_id: website.id, data: data
      #   )
      #
      #   # bad - hash pairs not alphabetically ordered
      #   SomeService.call(
      #     website_id: website.id,
      #     data: data
      #   )
      #
      #   # good
      #   SomeService.call(
      #     data: data,
      #     website_id: website.id
      #   )
      class MultilineHashArgumentStyle < Base
        extend AutoCorrector

        MSG = "Hash arguments in multiline calls should be one per line " \
              "and alphabetically ordered."

        # Check send nodes for hash arguments that need reformatting.
        #
        # @param [RuboCop::AST::Node] node The send node.
        # @return [void]
        def on_send(node)
          return unless multiline_call_with_hash?(node)

          hash_arg = find_hash_argument(node)
          return unless hash_arg
          return unless needs_correction?(hash_arg)

          add_offense(hash_arg) do |corrector|
            autocorrect(corrector, hash_arg)
          end
        end
        alias on_csend on_send

        private

        # Check if this is a multiline call with closing paren on own line.
        #
        # @param [RuboCop::AST::Node] node The send node.
        # @return [Boolean]
        def multiline_call_with_hash?(node)
          node.parenthesized? && closing_paren_on_own_line?(node)
        end

        # Check if closing paren is on its own line (after last argument).
        #
        # @param [RuboCop::AST::Node] node The send node.
        # @return [Boolean]
        def closing_paren_on_own_line?(node)
          last_arg = node.last_argument
          if last_arg
            node.loc.end.line > last_arg.loc.last_line
          else
            false
          end
        end

        # Find hash argument in the call (if any).
        #
        # @param [RuboCop::AST::Node] node The send node.
        # @return [RuboCop::AST::Node, nil]
        def find_hash_argument(node)
          node.arguments.find(&:hash_type?)
        end

        # Check if hash needs correction (same line or unordered).
        #
        # @param [RuboCop::AST::Node] hash_arg The hash node.
        # @return [Boolean]
        def needs_correction?(hash_arg)
          pairs = hash_arg.pairs
          return false if pairs.size < 2

          multiple_pairs_on_same_line?(pairs) || !pairs_alphabetically_ordered?(pairs)
        end

        # Check if multiple pairs are on the same line.
        #
        # @param [Array<RuboCop::AST::Node>] pairs The hash pairs.
        # @return [Boolean]
        def multiple_pairs_on_same_line?(pairs)
          lines = pairs.map { |pair| pair.loc.line }
          lines.size != lines.uniq.size
        end

        # Check if pairs are alphabetically ordered by key name.
        #
        # @param [Array<RuboCop::AST::Node>] pairs The hash pairs.
        # @return [Boolean]
        def pairs_alphabetically_ordered?(pairs)
          key_names = pairs.map { |pair| extract_key_name(pair) }
          key_names == key_names.sort
        end

        # Extract the key name as a string for sorting.
        #
        # @param [RuboCop::AST::Node] pair The hash pair node.
        # @return [String]
        def extract_key_name(pair)
          key = pair.key
          if key.type?(:sym, :str)
            key.value.to_s
          else
            key.source
          end
        end

        # Autocorrect by reordering and splitting pairs.
        #
        # @param [RuboCop::Cop::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] hash_arg The hash node.
        # @return [void]
        def autocorrect(corrector, hash_arg)
          pairs       = hash_arg.pairs
          sorted      = pairs.sort_by { |pair| extract_key_name(pair) }
          indentation = calculate_indentation(pairs.first)
          replacement = build_replacement(sorted, indentation)

          corrector.replace(hash_arg, replacement)
        end

        # Calculate indentation for reformatted pairs.
        #
        # @param [RuboCop::AST::Node] first_pair The first pair node.
        # @return [String]
        def calculate_indentation(first_pair)
          " " * first_pair.loc.column
        end

        # Build the replacement string with sorted pairs on separate lines.
        #
        # @param [Array<RuboCop::AST::Node>] sorted_pairs The sorted pairs.
        # @param [String] indentation The indentation string.
        # @return [String]
        def build_replacement(sorted_pairs, indentation)
          sorted_pairs.map.with_index do |pair, index|
            prefix = index.zero? ? "" : indentation
            suffix = index == sorted_pairs.size - 1 ? "" : ","
            "#{prefix}#{pair.source}#{suffix}"
          end.join("\n")
        end
      end
    end
  end
end
