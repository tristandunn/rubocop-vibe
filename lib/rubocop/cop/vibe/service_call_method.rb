# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces that service objects define both `self.call` and `call` methods.
      #
      # Service objects should provide a consistent public interface through
      # a `self.call` class method that delegates to an instance `call` method.
      #
      # @example
      #   # bad - missing both methods
      #   class MyService
      #     def perform
      #       # ...
      #     end
      #   end
      #
      #   # bad - missing instance call
      #   class MyService
      #     def self.call(arg)
      #       # ...
      #     end
      #   end
      #
      #   # bad - missing self.call
      #   class MyService
      #     def call
      #       # ...
      #     end
      #   end
      #
      #   # good
      #   class MyService
      #     def self.call(arg)
      #       new(arg).call
      #     end
      #
      #     def call
      #       # implementation
      #     end
      #   end
      class ServiceCallMethod < Base
        MSG = "Service objects should define `self.call` and `call` methods."

        SERVICE_FILE_PATTERN = %r{app/services/.*\.rb\z}

        # @!method class_call_method?(node)
        #   Check if node is a self.call class method definition.
        def_node_search :class_call_method?, <<~PATTERN
          (defs _ :call ...)
        PATTERN

        # @!method instance_call_method?(node)
        #   Check if node is a call instance method definition.
        def_node_search :instance_call_method?, <<~PATTERN
          (def :call ...)
        PATTERN

        # Check class definitions for missing call methods.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @return [void]
        def on_class(node)
          return unless service_file?
          return if class_call_method?(node) && instance_call_method?(node)

          add_offense(node.loc.name)
        end

        private

        # Check if current file is a service file.
        #
        # @return [Boolean]
        def service_file?
          processed_source.file_path.match?(SERVICE_FILE_PATTERN)
        end
      end
    end
  end
end
