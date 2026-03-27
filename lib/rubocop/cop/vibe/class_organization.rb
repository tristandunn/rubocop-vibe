# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces consistent organization of class definitions.
      #
      # For Rails models, enforces: concerns → constants → associations → validations →
      # callbacks → scopes → class methods → instance methods → protected → private.
      #
      # For regular classes, enforces: includes → constants → initialize → class methods →
      # instance methods → protected → private.
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
      class ClassOrganization < Base
        extend AutoCorrector

        ASSOCIATIONS = %i(belongs_to has_one has_many has_and_belongs_to_many).freeze
        CALLBACKS = %i(
          before_validation after_validation
          before_save after_save around_save
          before_create after_create around_create
          before_update after_update around_update
          before_destroy after_destroy around_destroy
          after_commit after_rollback
          after_initialize after_find after_touch
        ).freeze
        CLASS_MSG = "Class elements should be ordered: includes → constants → initialize → " \
                    "class methods → instance methods → protected → private."
        CLASS_PRIORITIES = {
          concerns:          10,
          constants:         20,
          initialize:        30,
          class_methods:     40,
          instance_methods:  50,
          protected_methods: 60,
          private_methods:   70
        }.freeze
        MODEL_MSG = "Model elements should be ordered: concerns → constants → associations → " \
                    "validations → callbacks → scopes → class methods → instance methods → " \
                    "protected → private."
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
        VALIDATIONS = %i(
          validates validate validates_each validates_with
          validates_absence_of validates_acceptance_of validates_confirmation_of
          validates_exclusion_of validates_format_of validates_inclusion_of
          validates_length_of validates_numericality_of validates_presence_of
          validates_size_of validates_uniqueness_of validates_associated
        ).freeze
        VISIBILITY_CATEGORIES = {
          protected: :protected_methods,
          private:   :private_methods,
          public:    :instance_methods
        }.freeze

        # Check and register violations.
        #
        # @param [RuboCop::AST::Node] class_node The class node.
        # @param [Array<Hash>] elements The elements.
        # @param [Boolean] is_model Whether this is a Rails model.
        # @return [void]
        def check_violations(class_node, elements, is_model)
          violations = find_violations(elements)

          return if violations.empty?

          message = is_model ? MODEL_MSG : CLASS_MSG

          add_offense(violations.first[:node], message: message) do |corrector|
            autocorrect(corrector, class_node, elements)
          end
        end

        # Check class nodes for organization.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @return [void]
        def on_class(node)
          is_model      = rails_model?(node)
          is_controller = rails_controller?(node)

          return if !is_model && !is_controller && !node.body

          elements = extract_elements(node, is_model: is_model, is_controller: is_controller)

          return if elements.size < 2

          check_violations(node, elements, is_model)
        end

        private

        # Auto-correct by sorting elements within each visibility section.
        #
        # @param [RuboCop::AST::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] _class_node The class node.
        # @param [Array<Hash>] elements The list of elements.
        # @return [void]
        def autocorrect(corrector, _class_node, elements)
          elements.group_by { |e| e[:visibility] }.each_value do |section|
            sorted = sort_elements(section)

            next if sorted == section

            autocorrect_group(corrector, section, sorted)
          end
        end

        # Auto-correct a single group of elements.
        #
        # @param [RuboCop::AST::Corrector] corrector The corrector.
        # @param [Array<Hash>] group The original elements.
        # @param [Array<Hash>] sorted The sorted elements.
        # @return [void]
        def autocorrect_group(corrector, group, sorted)
          sorted.each_with_index do |element, idx|
            original = group[idx]

            next if element[:node] == original[:node]

            corrector.replace(
              node_range_with_comments(original[:node]),
              source_with_comments(element[:node])
            )
          end
        end

        # Build element hash for a node.
        #
        # @param [RuboCop::AST::Node] child The node.
        # @param [Symbol] visibility The current visibility.
        # @param [Integer] index The original index.
        # @param [Boolean] is_model Whether this is a Rails model.
        # @param [Boolean] is_controller Whether this is a Rails controller.
        # @return [Hash]
        # @return [nil]
        def build_element(child, visibility, index, is_model, is_controller)
          return unless categorizable?(child)

          category = categorize_node(child, visibility, is_model)

          return unless category

          # Skip public instance methods in controllers (Rails/ActionOrder handles them).
          return if is_controller && category == :instance_methods && visibility == :public

          element_hash(child, category, visibility, index, is_model)
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
          return :constants if node.casgn_type?

          return nil if visibility_modifier?(node)

          send_category(node, is_model)
        end

        # Collect elements from body nodes.
        #
        # @param [RuboCop::AST::Node] body The body node.
        # @param [Boolean] is_model Whether this is a Rails model.
        # @param [Boolean] is_controller Whether this is a Rails controller.
        # @return [Array<Hash>] Array of element hashes.
        def collect_elements(body, is_model, is_controller)
          visibility = :public
          elements   = []
          index      = 0

          process_body_nodes(body).each do |child|
            visibility = child.method_name if visibility_modifier?(child)

            element = build_element(child, visibility, index, is_model, is_controller)

            elements << element and index += 1 if element
          end

          elements
        end

        # Get comments immediately before a node.
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

        # Get comments indexed by line number for fast lookup.
        #
        # @return [Hash<Integer, Parser::Source::Comment>] Comments keyed by line.
        def comments_by_line
          @comments_by_line ||= processed_source.comments.to_h { |c| [c.location.line, c] }
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
            sort_key:       sort_key_for(category, node)
          }
        end

        # Extract and categorize elements from the class.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @param [Boolean] is_model Whether this is a Rails model.
        # @param [Boolean] is_controller Whether this is a Rails controller.
        # @return [Array<Hash>] Array of element info.
        def extract_elements(node, is_model:, is_controller: false)
          if node.body
            collect_elements(node.body, is_model, is_controller)
          else
            []
          end
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

        # Get the source range of a node including preceding comments.
        #
        # @param [RuboCop::AST::Node] node The node.
        # @return [Parser::Source::Range]
        def node_range_with_comments(node)
          comment_list = comments_before(node)

          start_range = comment_list.any? ? comment_list.first.source_range : node.source_range

          start_range.join(node.source_range)
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

        # Check if this is a Rails controller.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @return [Boolean]
        def rails_controller?(node)
          return false unless node.parent_class

          parent_name = node.parent_class.const_name

          return false unless parent_name

          parent_name == "ApplicationController" ||
            parent_name == "ActionController::Base" ||
            parent_name.end_with?("::ApplicationController")
        end

        # Check if this is a Rails model.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @return [Boolean]
        def rails_model?(node)
          return false unless node.parent_class

          parent_name = node.parent_class.const_name

          return false unless parent_name

          parent_name == "ApplicationRecord" ||
            parent_name == "ActiveRecord::Base" ||
            parent_name.end_with?("::ApplicationRecord")
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

        # Sort elements by priority, sort key, and original index.
        #
        # @param [Array<Hash>] elements The list of elements.
        # @return [Array<Hash>]
        def sort_elements(elements)
          elements.sort_by { |e| [e[:priority], e[:sort_key], e[:original_index]] }
        end

        # Get sort key for alphabetical ordering within category.
        #
        # @param [Symbol] category The category.
        # @param [RuboCop::AST::Node] node The node.
        # @return [String]
        def sort_key_for(category, node)
          sortable = %i(scopes class_methods instance_methods protected_methods private_methods)

          return "" unless sortable.include?(category)
          return scope_sort_key(node) if category == :scopes
          return "!" if category == :class_methods && node.method?(:call)

          node.method_name.to_s
        end

        # Get the source of a node including preceding comments.
        #
        # @param [RuboCop::AST::Node] node The node.
        # @return [String]
        def source_with_comments(node)
          node_range_with_comments(node).source
        end

        # Check if node is a validation method.
        #
        # @param [RuboCop::AST::Node] node The node to check.
        # @return [Boolean]
        def validation_method?(node)
          VALIDATIONS.include?(node.method_name) ||
            node.method_name.to_s.start_with?("validates_")
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

        # Check if element violates category ordering.
        #
        # @param [Hash] current The current element.
        # @param [Hash] following The following element.
        # @return [Boolean]
        def violates_category_order?(current, following)
          current[:priority] > following[:priority]
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

        # Get category for visibility-based instance methods.
        #
        # @param [Symbol] visibility The visibility.
        # @return [Symbol]
        # @return [nil]
        def visibility_method_category(visibility)
          VISIBILITY_CATEGORIES[visibility]
        end

        # Check if node is a visibility modifier (public, protected, private).
        #
        # @param [RuboCop::AST::Node] node The node to check.
        # @return [Boolean]
        def visibility_modifier?(node)
          node.send_type? && node.receiver.nil? &&
            %i(public protected private).include?(node.method_name)
        end
      end
    end
  end
end
