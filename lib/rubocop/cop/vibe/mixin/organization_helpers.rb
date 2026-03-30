# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Low-level helpers for node ordering and comment handling.
      #
      # Used by BodyOrganization to handle source ranges, comments,
      # visibility modifiers, and node replacement during autocorrect.
      module OrganizationHelpers
        ATTR_SORT_ORDER = { attr_accessor: "!0", attr_reader: "!1", attr_writer: "!2" }.freeze
        VISIBILITY_CATEGORIES = {
          protected: :protected_methods,
          private:   :private_methods,
          public:    :instance_methods
        }.freeze

        private

        # Check if node is an attr method.
        def attr_method?(node)
          node.send_type? && ATTR_SORT_ORDER.key?(node.method_name)
        end

        # Get comments immediately before a node.
        def comments_before(node)
          consecutive   = []
          expected_line = node.first_line - 1

          while (comment = comments_by_line[expected_line])
            consecutive.unshift(comment)
            expected_line -= 1
          end

          consecutive
        end

        # Get comments indexed by line number for fast lookup.
        def comments_by_line
          @comments_by_line ||= processed_source.comments.to_h { |c| [c.location.line, c] }
        end

        # Get the source range of a node including preceding comments.
        def node_range_with_comments(node)
          comment_list = comments_before(node)
          start_range  = comment_list.any? ? comment_list.first.source_range : node.source_range
          start_range.join(node.source_range)
        end

        # Process body nodes to get a flat list.
        def process_body_nodes(body)
          if body.begin_type?
            body.children
          else
            [body]
          end
        end

        # Replace nodes during auto-correct.
        def replace_nodes(corrector, group, sorted)
          sorted.each_with_index do |element, idx|
            original = group[idx]

            next if element[:node] == original[:node]

            corrector.replace(node_range_with_comments(original[:node]),
                              node_range_with_comments(element[:node]).source)
          end
        end

        # Get category for visibility-based instance methods.
        def visibility_method_category(visibility)
          VISIBILITY_CATEGORIES[visibility]
        end

        # Check if node is a visibility modifier.
        def visibility_modifier?(node)
          node.send_type? && node.receiver.nil? &&
            %i(public protected private).include?(node.method_name)
        end
      end
    end
  end
end
