# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces alphabetical ordering of keyword arguments in method definitions
      # and their associated YARD `@param` documentation tags.
      #
      # @example
      #   # bad
      #   # @param id [String] the identifier
      #   # @param content [String] the body
      #   def initialize(id:, content:)
      #   end
      #
      #   # good
      #   # @param content [String] the body
      #   # @param id [String] the identifier
      #   def initialize(content:, id:)
      #   end
      class KeywordArgumentOrder < Base
        extend AutoCorrector

        MSG = "Order keyword arguments alphabetically."

        # Check method definitions for keyword argument ordering.
        #
        # @param [RuboCop::AST::Node] node The def node.
        # @return [void]
        def on_def(node)
          return unless node.arguments?

          kwargs = extract_keyword_arguments(node)

          return if kwargs.size < 2
          return if alphabetically_ordered?(kwargs)

          add_offense(node.arguments) do |corrector|
            autocorrect(corrector, node, kwargs)
          end
        end
        alias on_defs on_def

        private

        # Extract keyword arguments from a method definition.
        #
        # @param [RuboCop::AST::Node] node The def node.
        # @return [Array<RuboCop::AST::Node>]
        def extract_keyword_arguments(node)
          node.arguments.select { |arg| arg.type?(:kwarg, :kwoptarg) }
        end

        # Check if keyword arguments are correctly ordered.
        #
        # Required kwargs come first (alphabetically), then optional kwargs (alphabetically).
        #
        # @param [Array<RuboCop::AST::Node>] kwargs The keyword arguments.
        # @return [Boolean]
        def alphabetically_ordered?(kwargs)
          kwargs == kwargs.sort_by { |arg| kwarg_sort_key(arg) }
        end

        # Generate a sort key for a keyword argument.
        #
        # Required kwargs come first alphabetically, then optional kwargs alphabetically.
        #
        # @param [RuboCop::AST::Node] arg The argument node.
        # @return [Array]
        def kwarg_sort_key(arg)
          # kwargs array is pre-filtered to only include kwarg/kwoptarg types
          if arg.kwarg_type?
            [0, arg.name.to_s]
          else
            [1, arg.name.to_s]
          end
        end

        # Auto-correct by reordering keyword arguments and documentation.
        #
        # @param [RuboCop::AST::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] node The def node.
        # @param [Array<RuboCop::AST::Node>] kwargs The keyword arguments.
        # @return [void]
        def autocorrect(corrector, node, kwargs)
          autocorrect_arguments(corrector, node)
          autocorrect_documentation(corrector, node, kwargs)
        end

        # Auto-correct keyword arguments in the method signature.
        #
        # @param [RuboCop::AST::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] node The def node.
        # @return [void]
        def autocorrect_arguments(corrector, node)
          args          = node.arguments.to_a
          sorted_args   = args.sort_by { |arg| sort_key(arg) }
          sorted_source = sorted_args.map(&:source).join(", ")

          args_range = args.first.source_range.join(args.last.source_range)

          corrector.replace(args_range, sorted_source)
        end

        # Generate a sort key for an argument.
        #
        # Positional arguments come first, then required keyword arguments
        # alphabetically, then optional keyword arguments alphabetically.
        #
        # @param [RuboCop::AST::Node] arg The argument node.
        # @return [Array]
        def sort_key(arg)
          case arg.type
          when :kwarg
            [1, arg.name.to_s]
          when :kwoptarg
            [2, arg.name.to_s]
          else
            [0, ""]
          end
        end

        # Auto-correct YARD @param documentation.
        #
        # @param [RuboCop::AST::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] node The def node.
        # @param [Array<RuboCop::AST::Node>] kwargs The keyword arguments.
        # @return [void]
        def autocorrect_documentation(corrector, node, kwargs)
          comments = preceding_comments(node)

          return if comments.empty?

          param_comments = extract_param_comments(comments, kwargs)

          return if param_comments.empty?

          sorted_kwarg_names = kwargs.sort_by { |arg| sort_key(arg) }.map { |arg| arg.name.to_s }

          reorder_param_comments(corrector, param_comments, sorted_kwarg_names)
        end

        # Get comments preceding a node.
        #
        # @param [RuboCop::AST::Node] node The node.
        # @return [Array<Parser::Source::Comment>]
        def preceding_comments(node)
          processed_source.ast_with_comments[node] || []
        end

        # Extract @param comments for keyword arguments.
        #
        # @param [Array<Parser::Source::Comment>] comments The comments.
        # @param [Array<RuboCop::AST::Node>] kwargs The keyword arguments.
        # @return [Array<Parser::Source::Comment>]
        def extract_param_comments(comments, kwargs)
          kwarg_names = kwargs.map { |arg| arg.name.to_s }

          comments.select do |comment|
            match = comment.text.match(/@param\s+(\w+)/)

            match && kwarg_names.include?(match[1])
          end
        end

        # Reorder @param comments to match argument order.
        #
        # @param [RuboCop::AST::Corrector] corrector The corrector.
        # @param [Array<Parser::Source::Comment>] param_comments The param comments.
        # @param [Array<String>] sorted_kwarg_names The sorted keyword argument names.
        # @return [void]
        def reorder_param_comments(corrector, param_comments, sorted_kwarg_names)
          sorted = param_comments.sort_by do |comment|
            match = comment.text.match(/@param\s+(\w+)/)

            sorted_kwarg_names.index(match[1]) || Float::INFINITY
          end

          param_comments.each_with_index do |comment, index|
            sorted_comment = sorted[index]

            next if comment == sorted_comment

            corrector.replace(comment, sorted_comment.text)
          end
        end
      end
    end
  end
end
