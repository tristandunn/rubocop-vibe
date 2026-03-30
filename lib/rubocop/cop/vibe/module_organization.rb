# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces consistent organization of module definitions.
      #
      # Enforces: includes/extends → constants → attr → class methods →
      # instance methods → protected → private.
      #
      # Within each category, methods are sorted alphabetically.
      #
      # @example
      #   # bad
      #   module Helper
      #     def zebra
      #     end
      #
      #     def alpha
      #     end
      #
      #     include Foo
      #   end
      #
      #   # good
      #   module Helper
      #     include Foo
      #
      #     def alpha
      #     end
      #
      #     def zebra
      #     end
      #   end
      class ModuleOrganization < Base
        extend AutoCorrector
        include BodyOrganization

        MODULE_MSG = "Module elements should be ordered: includes/extends → constants → attr → " \
                     "class methods → instance methods → protected → private."
        MODULE_PRIORITIES = {
          concerns:          10,
          constants:         20,
          attr_methods:      25,
          class_methods:     35,
          instance_methods:  40,
          protected_methods: 50,
          private_methods:   60
        }.freeze

        # Check module nodes for organization.
        #
        # @param [RuboCop::AST::Node] node The module node.
        # @return [void]
        def on_module(node)
          return unless node.body

          elements = collect_body_elements(node.body)

          return if elements.size < 2

          check_body_violations(node, elements)
        end

        private

        # Categorize send nodes for modules.
        #
        # @param [RuboCop::AST::Node] node The node to categorize.
        # @param [Symbol] _visibility The current visibility.
        # @return [Symbol]
        # @return [nil]
        def categorize_send_node(node, _visibility)
          return :concerns if node.method?(:include) || node.method?(:extend)

          nil
        end

        # Get the priority hash.
        #
        # @return [Hash]
        def priorities
          MODULE_PRIORITIES
        end

        # Get sort key for alphabetical ordering within category.
        #
        # @param [Symbol] category The category.
        # @param [RuboCop::AST::Node] node The node.
        # @return [String]
        def sort_key_for(category, node)
          sortable = %i(class_methods instance_methods protected_methods private_methods)

          return "" unless sortable.include?(category)
          return ATTR_SORT_ORDER[node.method_name] if attr_method?(node)

          node.method_name.to_s
        end

        # Get the violation message.
        #
        # @return [String]
        def violation_message
          MODULE_MSG
        end
      end
    end
  end
end
