# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces consistent organization of Rails model definitions.
      #
      # @example
      #   # bad
      #   class User < ApplicationRecord
      #     def admin?
      #       role == "admin"
      #     end
      #
      #     validates :name, presence: true
      #
      #     has_many :posts
      #   end
      #
      #   # good
      #   class User < ApplicationRecord
      #     has_many :posts
      #
      #     validates :name, presence: true
      #
      #     def admin?
      #       role == "admin"
      #     end
      #   end
      class ModelOrganization < Base
        extend AutoCorrector

        MODEL_MSG = "Model elements should be ordered: concerns → constants → associations → " \
                    "validations → callbacks → scopes → class methods → instance methods → " \
                    "protected → private."
        CLASS_MSG = "Class elements should be ordered: includes → constants → initialize → " \
                    "class methods → instance methods → protected → private."

        ASSOCIATIONS = %i(belongs_to has_one has_many has_and_belongs_to_many).freeze
        VALIDATIONS = %i(
          validates validate validates_each validates_with
          validates_absence_of validates_acceptance_of validates_confirmation_of
          validates_exclusion_of validates_format_of validates_inclusion_of
          validates_length_of validates_numericality_of validates_presence_of
          validates_size_of validates_uniqueness_of validates_associated
        ).freeze
        CALLBACKS = %i(
          before_validation after_validation
          before_save after_save around_save
          before_create after_create around_create
          before_update after_update around_update
          before_destroy after_destroy around_destroy
          after_commit after_rollback
          after_initialize after_find after_touch
        ).freeze
        MODEL_PRIORITIES = {
          concerns:          10,
          constants:         20,
          associations:      30,
          validations:       40,
          callbacks:         50,
          scopes:            60,
          class_methods:     70,
          instance_methods:  80,
          protected_methods: 90,
          private_methods:   100
        }.freeze
        CLASS_PRIORITIES = {
          concerns:          10,
          constants:         20,
          initialize:        30,
          class_methods:     40,
          instance_methods:  50,
          protected_methods: 60,
          private_methods:   70
        }.freeze
        VISIBILITY_CATEGORIES = {
          protected: :protected_methods,
          private:   :private_methods,
          public:    :instance_methods
        }.freeze

        # @!method visibility_modifier?(node)
        #   Check if node is a visibility modifier (public, protected, private).
        def_node_matcher :visibility_modifier?, <<~PATTERN
          (send nil? {:public :protected :private})
        PATTERN

        # Check and register violations.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @param [Array<Hash>] elements The elements.
        # @param [Boolean] is_model Whether this is a Rails model.
        # @return [void]
        def check_violations(node, elements, is_model)
          violations = find_violations(elements)
          message    = is_model ? MODEL_MSG : CLASS_MSG

          violations.each do |element|
            add_offense(element[:node], message: message) do |corrector|
              autocorrect(corrector, node, elements)
            end
          end
        end

        # Check class nodes for organization.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @return [void]
        def on_class(node)
          is_model = rails_model?(node)
          return if !is_model && !node.body

          elements = extract_elements(node, is_model)
          return if elements.size < 2

          check_violations(node, elements, is_model)
        end

        private

        # Check if this is a Rails model.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @return [Boolean]
        def rails_model?(node)
          return false unless node.parent_class

          parent_name = node.parent_class.const_name
          return false unless parent_name

          # Check for direct ActiveRecord inheritance
          parent_name == "ApplicationRecord" ||
            parent_name == "ActiveRecord::Base" ||
            parent_name.end_with?("::ApplicationRecord")
        end

        # Extract and categorize elements from the class.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @param [Boolean] is_model Whether this is a Rails model.
        # @return [Array<Hash>] Array of element info.
        def extract_elements(node, is_model)
          if node.body
            collect_elements(node.body, is_model)
          else
            []
          end
        end

        # Collect elements from body nodes.
        #
        # @param [RuboCop::AST::Node] body The body node.
        # @param [Boolean] is_model Whether this is a Rails model.
        # @return [Array<Hash>] Array of element hashes.
        def collect_elements(body, is_model)
          visibility = :public
          elements   = []
          index      = 0
          process_body_nodes(body).each do |child|
            visibility = child.method_name if visibility_modifier?(child)

            element = build_element(child, visibility, index, is_model)
            elements << element and index += 1 if element
          end

          elements
        end

        # Build element hash for a node.
        #
        # @param [RuboCop::AST::Node] child The node.
        # @param [Symbol] visibility The current visibility.
        # @param [Integer] index The original index.
        # @param [Boolean] is_model Whether this is a Rails model.
        # @return [Hash]
        # @return [nil]
        def build_element(child, visibility, index, is_model)
          return unless categorizable?(child)

          category = categorize_node(child, visibility, is_model)
          return unless category

          element_hash(child, category, visibility, index, is_model)
        end

        # Create element hash.
        #
        # @param [RuboCop::AST::Node] node The node.
        # @param [Symbol] category The category.
        # @param [Symbol] visibility The visibility.
        # @param [Integer] index The original index.
        # @param [Boolean] is_model Whether this is a Rails model.
        # @return [Hash]
        def element_hash(node, category, visibility, index, is_model)
          {
            node:           node,
            category:       category,
            visibility:     visibility,
            original_index: index,
            priority:       priority_for(category, node, is_model),
            sort_key:       sort_key_for(category, node),
            source:         extract_source_with_comments(node)
          }
        end

        # Extract source including preceding comments.
        #
        # Stores each line's content with its original column offset for later normalization.
        #
        # @param [RuboCop::AST::Node] node The node.
        # @return [Array<Hash>] Array of hashes with :text and :column.
        def extract_source_with_comments(node)
          lines = extract_comment_lines(node)
          lines.concat(extract_node_lines(node))
        end

        # Extract comment lines before a node.
        #
        # @param [RuboCop::AST::Node] node The node.
        # @return [Array<Hash>] Array of hashes with :text and :column.
        def extract_comment_lines(node)
          comments_before(node).map do |comment|
            { text: comment.text, column: comment.source_range.column }
          end
        end

        # Extract node source lines with column information.
        #
        # @param [RuboCop::AST::Node] node The node.
        # @return [Array<Hash>] Array of hashes with :text and :column.
        def extract_node_lines(node)
          node_column = node.source_range.column

          node.source.lines.map.with_index do |line, idx|
            col = idx.zero? ? node_column : line[/\A\s*/].length
            { text: line.chomp, column: col }
          end
        end

        # Get comments indexed by line number for fast lookup.
        #
        # @return [Hash<Integer, Parser::Source::Comment>] Comments keyed by line.
        def comments_by_line
          @comments_by_line ||= processed_source.comments.to_h { |c| [c.location.line, c] }
        end

        # Get comments immediately before a node.
        #
        # Loops backwards from the node until finding a non-comment line.
        # Only consecutive comments immediately before the node are included.
        #
        # @param [RuboCop::AST::Node] node The node.
        # @return [Array<Parser::Source::Comment>] Consecutive comments before node.
        def comments_before(node)
          consecutive   = []
          expected_line = node.first_line - 1

          while (comment = comments_by_line[expected_line])
            consecutive.unshift(comment)
            expected_line -= 1
          end

          consecutive
        end

        # Process body nodes to get a flat list.
        #
        # @param [RuboCop::AST::Node] body The body node.
        # @return [Array<RuboCop::AST::Node>]
        def process_body_nodes(body)
          if body.begin_type?
            body.children
          else
            [body]
          end
        end

        # Check if node should be categorized.
        #
        # @param [RuboCop::AST::Node] node The node to check.
        # @return [Boolean]
        def categorizable?(node)
          node.type?(:send, :any_def, :casgn)
        end

        # Categorize a node.
        #
        # @param [RuboCop::AST::Node] node The node to categorize.
        # @param [Symbol] visibility The current visibility.
        # @param [Boolean] is_model Whether this is a Rails model.
        # @return [Symbol]
        # @return [nil] When node doesn't fit a category.
        def categorize_node(node, visibility, is_model)
          return method_category(node, visibility) if node.any_def_type?
          return send_category(node, is_model) if node.send_type?

          :constants
        end

        # Categorize method nodes.
        #
        # @param [RuboCop::AST::Node] node The node to categorize.
        # @param [Symbol] visibility The current visibility.
        # @return [Symbol]
        def method_category(node, visibility)
          return :class_methods if node.defs_type?
          return :initialize if node.method?(:initialize) && visibility == :public

          visibility_method_category(visibility)
        end

        # Get category for visibility-based instance methods.
        #
        # @param [Symbol] visibility The visibility.
        # @return [Symbol]
        # @return [nil]
        def visibility_method_category(visibility)
          VISIBILITY_CATEGORIES[visibility]
        end

        # Categorize send nodes.
        #
        # @param [RuboCop::AST::Node] node The node to categorize.
        # @param [Boolean] is_model Whether this is a Rails model.
        # @return [Symbol]
        # @return [nil]
        def send_category(node, is_model)
          return :concerns if node.method?(:include)
          return nil unless is_model

          return :associations if ASSOCIATIONS.include?(node.method_name)
          return :validations if validation_method?(node)
          return :callbacks if CALLBACKS.include?(node.method_name)
          return :scopes if node.method?(:scope)

          nil
        end

        # Check if node is a validation method.
        #
        # @param [RuboCop::AST::Node] node The node to check.
        # @return [Boolean]
        def validation_method?(node)
          VALIDATIONS.include?(node.method_name) ||
            node.method_name.to_s.start_with?("validates_")
        end

        # Get priority for a category.
        #
        # @param [Symbol] category The category.
        # @param [RuboCop::AST::Node] _node The node.
        # @param [Boolean] is_model Whether this is a Rails model.
        # @return [Integer]
        def priority_for(category, _node, is_model)
          priorities = is_model ? MODEL_PRIORITIES : CLASS_PRIORITIES
          priorities[category] || 999
        end

        # Get sort key for alphabetical ordering within category.
        #
        # @param [Symbol] category The category.
        # @param [RuboCop::AST::Node] node The node.
        # @return [String]
        def sort_key_for(category, node)
          return "" unless %i(scopes class_methods instance_methods).include?(category)

          if category == :scopes
            scope_sort_key(node)
          else
            node.method_name.to_s
          end
        end

        # Get sort key for scope nodes.
        #
        # @param [RuboCop::AST::Node] node The scope node.
        # @return [String]
        def scope_sort_key(node)
          first_arg = node.first_argument
          return "" if first_arg.nil?
          return "" unless first_arg.sym_type?

          first_arg.value.to_s
        end

        # Find elements that violate ordering.
        #
        # @param [Array<Hash>] elements The list of elements.
        # @return [Array<Hash>] Elements that violate ordering.
        def find_violations(elements)
          violations = []

          elements.each_cons(2) do |current, following|
            violations << following if violates_order?(current, following)
          end

          violations.uniq
        end

        # Check if element violates ordering.
        #
        # @param [Hash] current The current element.
        # @param [Hash] following The following element.
        # @return [Boolean]
        def violates_order?(current, following)
          violates_category_order?(current, following) ||
            violates_alphabetical_order?(current, following)
        end

        # Check if element violates category ordering.
        #
        # @param [Hash] current The current element.
        # @param [Hash] following The following element.
        # @return [Boolean]
        def violates_category_order?(current, following)
          current[:priority] > following[:priority]
        end

        # Check if element violates alphabetical ordering.
        #
        # @param [Hash] current The current element.
        # @param [Hash] following The following element.
        # @return [Boolean]
        def violates_alphabetical_order?(current, following)
          current[:priority] == following[:priority] &&
            !current[:sort_key].empty? &&
            current[:sort_key] > following[:sort_key]
        end

        # Auto-correct by reordering elements.
        #
        # @param [RuboCop::AST::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] class_node The class node.
        # @param [Array<Hash>] elements The list of elements.
        # @return [void]
        def autocorrect(corrector, class_node, elements)
          sorted      = sort_elements(elements)
          base_column = calculate_base_indent(elements)
          replacement = build_replacement(sorted, base_column)
          range       = replacement_range(class_node, elements)
          corrector.replace(range, replacement.chomp)
        end

        # Calculate the source range to replace when autocorrecting.
        #
        # @param [RuboCop::AST::Node] class_node The class node.
        # @param [Array<Hash>] elements The list of elements.
        # @return [Parser::Source::Range]
        def replacement_range(class_node, elements)
          first_elem = elements.min_by { |e| e[:node].source_range.begin_pos }
          last_elem  = elements.max_by { |e| e[:node].source_range.end_pos }

          range_start = range_start_position(class_node, first_elem)
          range_end   = last_elem[:node].source_range.end_pos

          Parser::Source::Range.new(processed_source.buffer, range_start, range_end)
        end

        # Get the start position for replacement range.
        #
        # Includes any visibility modifiers that appear before the first element.
        #
        # @param [RuboCop::AST::Node] class_node The class node.
        # @param [Hash] first_elem The first element.
        # @return [Integer]
        def range_start_position(class_node, first_elem)
          first_node     = find_first_body_node(class_node, first_elem)
          first_comments = comments_before(first_node)
          first_range    = first_comments.any? ? first_comments.first.source_range : first_node.source_range

          first_range.begin_pos - first_range.column
        end

        # Find the first node in the class body, including visibility modifiers.
        #
        # @param [RuboCop::AST::Node] class_node The class node.
        # @param [Hash] first_elem The first categorizable element.
        # @return [RuboCop::AST::Node]
        def find_first_body_node(class_node, first_elem)
          first_elem_pos = first_elem[:node].source_range.begin_pos

          process_body_nodes(class_node.body).find do |child|
            child.source_range.begin_pos >= first_elem_pos || visibility_modifier?(child)
          end
        end

        # Sort elements by priority, sort key, and original index.
        #
        # @param [Array<Hash>] elements The list of elements.
        # @return [Array<Hash>]
        def sort_elements(elements)
          elements.sort_by { |e| [e[:priority], e[:sort_key], e[:original_index]] }
        end

        # Build replacement source for sorted elements.
        #
        # @param [Array<Hash>] sorted The sorted elements.
        # @param [Integer] base_column The base indentation column.
        # @return [String]
        def build_replacement(sorted, base_column)
          state = { parts: [], visibility: :public, category: nil, column: base_column }

          sorted.each { |element| process_element(element, state) }

          state[:parts].join.chomp
        end

        # Calculate base indentation column from the first element.
        #
        # @param [Array<Hash>] elements The list of elements.
        # @return [Integer] The base indentation column.
        def calculate_base_indent(elements)
          first_elem = elements.min_by { |e| e[:node].source_range.begin_pos }
          first_elem[:node].source_range.column
        end

        # Render source lines with normalized indentation.
        #
        # @param [Array<Hash>] source_lines Lines with :text and :column.
        # @param [Integer] base_column The target indentation column.
        # @return [String] The rendered source.
        def render_source(source_lines, base_column)
          min_column = source_lines.map { |l| l[:column] }.min
          indent     = " " * base_column

          source_lines.map do |line|
            relative_indent = " " * [0, line[:column] - min_column].max
            "#{indent}#{relative_indent}#{line[:text].lstrip}"
          end.join("\n")
        end

        # Process element for replacement.
        #
        # @param [Hash] element The element.
        # @param [Hash] state The state hash.
        # @return [void]
        def process_element(element, state)
          add_visibility_modifier(state, element[:visibility])
          state[:visibility] = element[:visibility]

          add_category_separator(state[:parts], element[:category], state[:category])
          state[:category] = element[:category]

          rendered_source = render_source(element[:source], state[:column])
          state[:parts] << rendered_source << "\n"
        end

        # Add visibility modifier if needed.
        #
        # @param [Hash] state The state hash.
        # @param [Symbol] new_visibility The new visibility.
        # @return [void]
        def add_visibility_modifier(state, new_visibility)
          return if new_visibility == state[:visibility]

          indent = " " * state[:column]
          state[:parts] << "\n" if state[:parts].any?
          state[:parts] << "#{indent}#{new_visibility}\n"
        end

        # Add blank line between elements.
        #
        # Adds a blank line before elements (except the first one) to maintain
        # readable spacing between class members.
        #
        # @param [Array<String>] parts The parts array.
        # @param [Symbol] _category The current category (unused but kept for API).
        # @param [Symbol] last_category The last category.
        # @return [void]
        def add_category_separator(parts, _category, last_category)
          parts << "\n" if last_category
        end
      end
    end
  end
end
