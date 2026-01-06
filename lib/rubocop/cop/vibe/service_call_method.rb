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

        # Check class definitions for missing call methods.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @return [void]
        def on_class(node)
          return unless service_file?
          return if class_call?(node) && instance_call?(node)

          add_offense(node.loc.name)
        end

        private

        # Check if current file is a service file.
        #
        # @return [Boolean]
        def service_file?
          processed_source.file_path.match?(SERVICE_FILE_PATTERN)
        end

        # Check if class has a self.call method.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @return [Boolean]
        def class_call?(node)
          return false unless node.body

          find_method(node, :defs, :call)
        end

        # Check if class has an instance call method.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @return [Boolean]
        def instance_call?(node)
          return false unless node.body

          find_method(node, :def, :call)
        end

        # Find a method definition in the class body.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @param [Symbol] type The method type (:def or :defs).
        # @param [Symbol] name The method name.
        # @return [Boolean]
        def find_method(node, type, name)
          body     = node.body
          children = body.begin_type? ? body.children : [body]

          children.any? do |child|
            child.type == type && child.method?(name)
          end
        end
      end
    end
  end
end
