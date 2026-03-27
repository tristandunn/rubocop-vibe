# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces that `validate` calls appear after `validates` declarations.
      #
      # Within a consecutive block of validates-family calls (no blank lines
      # between), all `validate :method` calls must come after all `validates*`
      # declarations. The order of `validate` calls relative to each other is
      # not enforced.
      #
      # @example
      #   # bad
      #   class User < ApplicationRecord
      #     validate :check_expiry
      #     validates :name, presence: true
      #   end
      #
      #   # good
      #   class User < ApplicationRecord
      #     validates :name, presence: true
      #     validate :check_expiry
      #   end
      #
      #   # good - blank line breaks the group
      #   class User < ApplicationRecord
      #     validate :check_expiry
      #
      #     validates :name, presence: true
      #   end
      class ValidateAfterValidates < Base
        extend AutoCorrector
        include AlignmentHelpers

        MSG = "Place `validate` calls after `validates` declarations."

        VALIDATES_METHODS = %i(
          validates validates_each validates_with
          validates_absence_of validates_acceptance_of validates_confirmation_of
          validates_exclusion_of validates_format_of validates_inclusion_of
          validates_length_of validates_numericality_of validates_presence_of
          validates_size_of validates_uniqueness_of validates_associated
        ).freeze

        VALIDATE_METHOD = :validate

        # Check class nodes for validate/validates ordering.
        #
        # @param [RuboCop::AST::Node] node The class node.
        # @return [void]
        def on_class(node)
          return unless rails_model?(node)
          return unless node.body

          check_validates_in_body(node.body)
        end

        private

        # Auto-correct by moving validate calls after validates* declarations.
        #
        # Preserves relative order within each tier.
        #
        # @param [RuboCop::AST::Corrector] corrector The corrector.
        # @param [Array<RuboCop::AST::Node>] group The validates group.
        # @return [void]
        def autocorrect(corrector, group)
          validates_nodes = group.select { |n| VALIDATES_METHODS.include?(n.method_name) }
          validate_nodes  = group.select { |n| n.method?(VALIDATE_METHOD) }
          sorted          = validates_nodes + validate_nodes

          group.each_with_index do |node, index|
            sorted_node = sorted[index]

            next if node == sorted_node

            corrector.replace(node, sorted_node.source)
          end
        end

        # Check ordering for a group of validates-family declarations.
        #
        # @param [Array<RuboCop::AST::Node>] group The validates group.
        # @return [void]
        def check_group_order(group)
          violations = find_violations(group)

          return if violations.empty?

          violations.each do |validate|
            add_offense(validate) do |corrector|
              autocorrect(corrector, group)
            end
          end
        end

        # Check validates-family declarations in a body node.
        #
        # @param [RuboCop::AST::Node] body The body node.
        # @return [void]
        def check_validates_in_body(body)
          statements = extract_statements(body)

          return if statements.size < 2

          groups = group_consecutive_statements(statements) { |s| validates_family?(s) }

          groups.each { |group| check_group_order(group) }
        end

        # Find validate calls that appear before validates* declarations.
        #
        # @param [Array<RuboCop::AST::Node>] group The validates group.
        # @return [Array<RuboCop::AST::Node>] Validate nodes that violate ordering.
        def find_violations(group)
          last_validates_index = group.rindex { |n| VALIDATES_METHODS.include?(n.method_name) }

          return [] if last_validates_index.nil?

          group.each_with_index.filter_map do |node, index|
            node if index < last_validates_index && node.method?(VALIDATE_METHOD)
          end
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

        # Check if a node is a validates-family declaration.
        #
        # @param [RuboCop::AST::Node] node The node to check.
        # @return [Boolean]
        def validates_family?(node)
          if node.send_type?
            VALIDATES_METHODS.include?(node.method_name) || node.method?(VALIDATE_METHOD)
          else
            false
          end
        end
      end
    end
  end
end
