# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces alphabetical ordering of arguments to `attr_reader`,
      # `attr_writer`, and `attr_accessor` declarations.
      #
      # @example
      #   # bad
      #   attr_reader :id, :content, :timestamp, :raw
      #
      #   # good
      #   attr_reader :content, :id, :raw, :timestamp
      #
      #   # bad
      #   attr_accessor :zebra, :apple
      #
      #   # good
      #   attr_accessor :apple, :zebra
      class AttrOrder < Base
        extend AutoCorrector

        MSG = "Order `%<method>s` arguments alphabetically."

        ATTR_METHODS = %i(attr_reader attr_writer attr_accessor).freeze

        # Check attr_* method calls for alphabetical ordering.
        #
        # @param [RuboCop::AST::Node] node The send node.
        # @return [void]
        def on_send(node)
          return unless attr_method?(node)
          return unless node.arguments.size > 1
          return if all_symbols?(node.arguments) && alphabetically_ordered?(node.arguments)

          add_offense(node, message: format(MSG, method: node.method_name)) do |corrector|
            autocorrect(corrector, node)
          end
        end
        alias on_csend on_send

        private

        # Check if the node is an attr_* method call.
        #
        # @param [RuboCop::AST::Node] node The send node.
        # @return [Boolean]
        def attr_method?(node)
          node.receiver.nil? && ATTR_METHODS.include?(node.method_name)
        end

        # Check if all arguments are symbols.
        #
        # @param [Array<RuboCop::AST::Node>] arguments The arguments.
        # @return [Boolean]
        def all_symbols?(arguments)
          arguments.all?(&:sym_type?)
        end

        # Check if arguments are alphabetically ordered.
        #
        # @param [Array<RuboCop::AST::Node>] arguments The arguments.
        # @return [Boolean]
        def alphabetically_ordered?(arguments)
          names = arguments.map { |arg| arg.value.to_s }

          names == names.sort
        end

        # Auto-correct by reordering arguments alphabetically.
        #
        # @param [RuboCop::AST::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] node The send node.
        # @return [void]
        def autocorrect(corrector, node)
          sorted_args   = node.arguments.sort_by { |arg| arg.value.to_s }
          sorted_source = sorted_args.map(&:source).join(", ")

          args_range = node.first_argument.source_range.join(node.last_argument.source_range)

          corrector.replace(args_range, sorted_source)
        end
      end
    end
  end
end
