# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces consistent organization of class definitions.
      #
      # For Rails models, enforces: concerns → constants → attr → associations →
      # validations → callbacks → scopes → class methods → instance methods →
      # protected → private.
      #
      # For regular classes, enforces: includes → constants → attr → initialize →
      # class methods → instance methods → protected → private.
      #
      # Within each visibility level, attr_accessor/attr_reader/attr_writer are ordered
      # first (in that order), followed by methods in alphabetical order.
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
        include BodyOrganization

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
        CLASS_MSG = "Class elements should be ordered: includes → constants → attr → initialize → " \
                    "class methods → instance methods → protected → private."
        CLASS_PRIORITIES = {
          concerns:          10,
          constants:         20,
          attr_methods:      25,
          initialize:        30,
          class_methods:     40,
          instance_methods:  50,
          protected_methods: 60,
          private_methods:   70
        }.freeze
        MODEL_MSG = "Model elements should be ordered: concerns → constants → attr → associations → " \
                    "validations → callbacks → scopes → class methods → instance methods → " \
                    "protected → private."
        MODEL_PRIORITIES = {
          concerns:          10,
          constants:         20,
          attr_methods:      25,
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

        # Check class nodes for organization.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @return [void]
        def on_class(node)
          @is_model      = rails_model?(node)
          @is_controller = rails_controller?(node)

          return if !@is_model && !@is_controller && !node.body
          return unless node.body

          elements = collect_class_elements(node.body)

          return if elements.size < 2

          check_body_violations(node, elements)
        end

        private

        # Categorize send nodes for classes.
        #
        # @param [RuboCop::AST::Node] node The node to categorize.
        # @param [Symbol] _visibility The current visibility.
        # @return [Symbol]
        # @return [nil]
        def categorize_send_node(node, _visibility)
          return :concerns if node.method?(:include)
          return nil unless @is_model

          return :associations if ASSOCIATIONS.include?(node.method_name)
          return :validations if validation_method?(node)
          return :callbacks if CALLBACKS.include?(node.method_name)
          return :scopes if node.method?(:scope)

          nil
        end

        # Collect elements from class body with controller filtering.
        #
        # @param [RuboCop::AST::Node] body The body node.
        # @return [Array<Hash>] Array of element hashes.
        def collect_class_elements(body)
          visibility = :public
          elements   = []

          process_body_nodes(body).each do |child|
            visibility = child.method_name if visibility_modifier?(child)
            element = build_body_element(child, visibility, elements.size)

            next if element.nil? || controller_public_instance_method?(element, visibility)

            elements << element
          end

          elements
        end

        # Check if element is a public instance method in a controller.
        def controller_public_instance_method?(element, visibility)
          @is_controller && element[:category] == :instance_methods && visibility == :public
        end

        # Get the priority hash for the current context.
        #
        # @return [Hash]
        def priorities
          if @is_model
            MODEL_PRIORITIES
          else
            CLASS_PRIORITIES
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

        # Get sort key for alphabetical ordering within category.
        #
        # @param [Symbol] category The category.
        # @param [RuboCop::AST::Node] node The node.
        # @return [String]
        def sort_key_for(category, node)
          sortable = %i(scopes class_methods instance_methods protected_methods private_methods)

          return "" unless sortable.include?(category)
          return ATTR_SORT_ORDER[node.method_name] if attr_method?(node)
          return scope_sort_key(node) if category == :scopes
          return "!" if category == :class_methods && node.method?(:call)

          node.method_name.to_s
        end

        # Check if node is a validation method.
        #
        # @param [RuboCop::AST::Node] node The node to check.
        # @return [Boolean]
        def validation_method?(node)
          VALIDATIONS.include?(node.method_name) ||
            node.method_name.to_s.start_with?("validates_")
        end

        # Get the violation message for the current context.
        #
        # @return [String]
        def violation_message
          if @is_model
            MODEL_MSG
          else
            CLASS_MSG
          end
        end
      end
    end
  end
end
