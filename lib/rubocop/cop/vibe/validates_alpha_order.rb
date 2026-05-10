# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces alphabetical ordering of consecutive `validates` declarations.
      #
      # Consecutive `validates` declarations (with no blank lines between) should be
      # alphabetically ordered by the first attribute name for better readability and
      # easier scanning. Groups are broken by blank lines or non-validates statements.
      #
      # @example
      #   # bad
      #   class User < ApplicationRecord
      #     validates :name, presence: true
      #     validates :age, numericality: true
      #   end
      #
      #   # good
      #   class User < ApplicationRecord
      #     validates :age, numericality: true
      #     validates :name, presence: true
      #   end
      #
      #   # good - blank line breaks the group
      #   class User < ApplicationRecord
      #     validates :z, presence: true
      #
      #     validates :a, presence: true
      #   end
      class ValidatesAlphaOrder < Base
        extend AutoCorrector
        include AlignmentHelpers

        MSG = "Order validates declarations alphabetically by attribute name."

        VALIDATES_METHODS = %i(
          validates validates_each validates_with
          validates_absence_of validates_acceptance_of validates_confirmation_of
          validates_exclusion_of validates_format_of validates_inclusion_of
          validates_length_of validates_numericality_of validates_presence_of
          validates_size_of validates_uniqueness_of validates_associated
        ).freeze

        # Check class nodes for validates ordering.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @return [void]
        def on_class(node)
          return unless rails_model?(node)
          return unless node.body

          check_validates_in_body(node.body)
        end

        private

        # Check if validates declarations are alphabetically ordered.
        #
        # @param [Array<RuboCop::AST::Node>] group The validates group.
        # @return [Boolean]
        def alphabetically_ordered?(group)
          names = group.map { |validates| extract_validates_name(validates) }

          names == names.sort
        end

        # Auto-correct by reordering validates declarations.
        #
        # @param [RuboCop::AST::Corrector] corrector The corrector.
        # @param [Array<RuboCop::AST::Node>] group The validates group.
        # @return [void]
        def autocorrect(corrector, group)
          sorted = group.sort_by { |validates| extract_validates_name(validates) }

          group.each_with_index do |validates, index|
            sorted_validates = sorted[index]

            next if validates == sorted_validates

            corrector.replace(validates, sorted_validates.source)
          end
        end

        # Check ordering for a group of validates declarations.
        #
        # @param [Array<RuboCop::AST::Node>] group The validates group.
        # @return [void]
        def check_group_order(group)
          return if alphabetically_ordered?(group)

          violations = find_ordering_violations(group)

          violations.each do |validates|
            add_offense(validates) do |corrector|
              autocorrect(corrector, group)
            end
          end
        end

        # Check validates declarations in a body node.
        #
        # @param [RuboCop::AST::Node] body The body node.
        # @return [void]
        def check_validates_in_body(body)
          statements = extract_statements(body)

          return if statements.size < 2

          groups = group_consecutive_statements(statements) { |statement| validates_declaration?(statement) }

          groups.each { |group| check_group_order(group) }
        end

        # Extract the attribute name from a validates declaration.
        #
        # @param [RuboCop::AST::Node] node The validates node.
        # @return [String]
        def extract_validates_name(node)
          node.first_argument.value.to_s
        end

        # Find validates declarations that violate ordering.
        #
        # @param [Array<RuboCop::AST::Node>] group The validates group.
        # @return [Array<RuboCop::AST::Node>] Validates that violate ordering.
        def find_ordering_violations(group)
          violations = []

          group.each_cons(2) do |current, following|
            violations << following if extract_validates_name(current) > extract_validates_name(following)
          end

          violations.uniq
        end

        # Check if this is a Rails model.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @return [Boolean]
        def rails_model?(node)
          if node.parent_class
            parent_name = node.parent_class.const_name.to_s
            parent_name == "ApplicationRecord" ||
              parent_name == "ActiveRecord::Base" ||
              parent_name.end_with?("::ApplicationRecord")
          else
            false
          end
        end

        # Check if a node is a validates declaration.
        #
        # @param [RuboCop::AST::Node] node The node to check.
        # @return [Boolean]
        def validates_declaration?(node)
          if node.send_type?
            VALIDATES_METHODS.include?(node.method_name)
          else
            false
          end
        end
      end
    end
  end
end
