# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Shared helper methods for organizing class and module bodies.
      #
      # Including cops must implement:
      #   - categorize_send_node(node, visibility) -> Symbol or nil
      #   - priorities -> Hash
      #   - sort_key_for(category, node) -> String
      #   - violation_message -> String
      module BodyOrganization
        include OrganizationHelpers

        private

        # Get category for attr methods based on visibility.
        def attr_category(visibility)
          if visibility == :public
            :attr_methods
          else
            visibility_method_category(visibility)
          end
        end

        # Auto-correct by sorting elements within each visibility section.
        def autocorrect(corrector, _container_node, elements)
          elements.group_by { |e| e[:visibility] }.each_value do |section|
            sorted = sort_elements(section)

            next if sorted == section

            replace_nodes(corrector, section, sorted)
          end
        end

        # Categorize a node using shared logic and cop-specific send categorization.
        def base_categorize_node(node, visibility)
          return method_category(node, visibility) if node.any_def_type?
          return :constants if node.casgn_type?
          return nil if visibility_modifier?(node)
          return attr_category(visibility) if attr_method?(node)

          categorize_send_node(node, visibility)
        end

        # Build element hash for a node.
        def build_body_element(child, visibility, index)
          return unless child.type?(:send, :any_def, :casgn)

          category = base_categorize_node(child, visibility)

          return unless category

          element_hash(child, category, visibility, index)
        end

        # Check and register violations.
        def check_body_violations(container_node, elements)
          violations = find_violations(elements)

          return if violations.empty?

          add_offense(violations.first[:node], message: violation_message) do |corrector|
            autocorrect(corrector, container_node, elements)
          end
        end

        # Collect elements from body nodes.
        def collect_body_elements(body)
          visibility = :public
          elements   = []

          process_body_nodes(body).each do |child|
            visibility = child.method_name if visibility_modifier?(child)
            element = build_body_element(child, visibility, elements.size)

            elements << element if element
          end

          elements
        end

        # Create element hash.
        def element_hash(node, category, visibility, index)
          {
            node:, category:, visibility:,
            original_index: index,
            priority:       priorities[category] || 999,
            sort_key:       sort_key_for(category, node)
          }
        end

        # Find elements that violate ordering.
        def find_violations(elements)
          elements.each_cons(2).filter_map do |current, following|
            following if violates_order?(current, following)
          end.uniq
        end

        # Categorize method nodes.
        def method_category(node, visibility)
          return :class_methods if node.defs_type?
          return :initialize if node.method?(:initialize) && visibility == :public

          visibility_method_category(visibility)
        end

        # Sort elements by priority, sort key, and original index.
        def sort_elements(elements)
          elements.sort_by { |e| [e[:priority], e[:sort_key], e[:original_index]] }
        end

        # Check if element violates alphabetical ordering.
        def violates_alphabetical_order?(current, following)
          current[:priority] == following[:priority] &&
            !current[:sort_key].empty? &&
            current[:sort_key] > following[:sort_key]
        end

        # Check if element violates ordering.
        def violates_order?(current, following)
          current[:priority] > following[:priority] ||
            violates_alphabetical_order?(current, following)
        end
      end
    end
  end
end
