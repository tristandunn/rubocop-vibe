# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces consistent ordering of describe blocks in RSpec files.
      #
      # Universal order: "class" → "constants" → ".class_method" → "#instance_method"
      # Models add: "associations" and "validations" between "constants" and methods.
      # Controllers add: RESTful actions between "constants" and methods.
      #
      # @example
      #   # bad
      #   describe User do
      #     describe "#name" do
      #     end
      #
      #     describe "class" do
      #     end
      #   end
      #
      #   # good (universal)
      #   describe Service do
      #     describe "class" do
      #     end
      #
      #     describe ".call" do
      #     end
      #
      #     describe "#process" do
      #     end
      #   end
      #
      #   # good (model with custom sections)
      #   describe User do
      #     describe "class" do
      #     end
      #
      #     describe "associations" do
      #     end
      #
      #     describe "validations" do
      #     end
      #
      #     describe ".find_active" do
      #     end
      #
      #     describe "#name" do
      #     end
      #   end
      class DescribeBlockOrder < Base
        extend AutoCorrector
        include SpecFileHelper

        MSG = "Describe blocks should be ordered: class → constants → .class_method → #instance_method."

        # Priority for non-special, non-method descriptions (e.g., "callbacks", "scopes")
        NON_SPECIAL_DESCRIPTION_PRIORITY = 300
        # Default priority for descriptions that can't be categorized (e.g., constants, variables)
        DEFAULT_PRIORITY = 999

        MODEL_ORDER        = %w(class associations validations).freeze
        CONTROLLER_ACTIONS = %w(index show new create edit update destroy).freeze
        SPECIAL_SECTIONS = {
          "class"        => 0,
          "constants"    => 5,
          "associations" => 10,
          "validations"  => 20
        }.freeze

        # @!method describe_block?(node)
        #   Check if node is a describe block (matches both `describe` and `RSpec.describe`).
        def_node_matcher :describe_block?, <<~PATTERN
          (block (send _ :describe ...) ...)
        PATTERN

        # Check block nodes for describe calls.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [void]
        def on_block(node)
          return unless spec_file?
          return unless top_level_describe?(node)

          describe_blocks = extract_describe_blocks(node)

          return if describe_blocks.size < 2

          violations = find_ordering_violations(describe_blocks)

          violations.each do |block_info|
            add_offense(block_info[:node]) do |corrector|
              autocorrect(corrector, describe_blocks)
            end
          end
        end
        alias on_numblock on_block

        private

        # Check if this is a top-level describe block.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [Boolean]
        def top_level_describe?(node)
          describe_block?(node) &&
            node.each_ancestor(:block).none? { |ancestor| describe_block?(ancestor) }
        end

        # Extract second-level describe blocks.
        #
        # @param [RuboCop::AST::Node] top_node The top-level describe block.
        # @return [Array<Hash>] Array of describe block info.
        def extract_describe_blocks(top_node)
          if top_node.body
            block_nodes(top_node).map.with_index { |node, index| build_block_info(node, index) }
          else
            []
          end
        end

        # Get block nodes from the top-level describe.
        #
        # @param [RuboCop::AST::Node] top_node The top-level describe block.
        # @return [Array<RuboCop::AST::Node>]
        def block_nodes(top_node)
          children = top_node.body.begin_type? ? top_node.body.children : [top_node.body]

          children.select { |child| child.block_type? && child.method?(:describe) }
        end

        # Build block information hash.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @param [Integer] index The original index.
        # @return [Hash] Block information.
        def build_block_info(node, index)
          description = extract_description(node)

          {
            node:           node,
            original_index: index,
            description:    description,
            priority:       categorize_description(description)
          }
        end

        # Extract description string from describe block.
        #
        # Only string and symbol literals are supported for ordering.
        # Constants and variables return nil and will be assigned DEFAULT_PRIORITY.
        #
        # @param [RuboCop::AST::Node] node The describe block node.
        # @return [String] The description string from a string or symbol literal.
        # @return [nil] When description is not a string/symbol literal.
        def extract_description(node)
          first_arg = node.send_node.first_argument

          return unless first_arg

          if first_arg.str_type?
            first_arg.value
          elsif first_arg.sym_type?
            first_arg.value.to_s
          end
          # Returns nil for constants/variables - they get DEFAULT_PRIORITY.
        end

        # Categorize description and assign priority.
        #
        # Universal order: class (0) → constants (5) → .class_method (100) → #instance_method (200)
        # Models insert: associations (10), validations (20) between class and methods.
        # Controllers insert: RESTful actions (30-36) between class and methods.
        # Non-special descriptions get NON_SPECIAL_DESCRIPTION_PRIORITY (300).
        # nil descriptions get DEFAULT_PRIORITY (999).
        #
        # @param [String, nil] description The describe block description.
        # @return [Integer] Priority number (lower = earlier).
        def categorize_description(description)
          if description
            special_section_priority(description) ||
              controller_action_priority(description) ||
              method_priority(description) ||
              NON_SPECIAL_DESCRIPTION_PRIORITY
          else
            DEFAULT_PRIORITY
          end
        end

        # Get priority for special sections.
        #
        # @param [String] description The describe block description.
        # @return [Integer]
        # @return [nil] When not a special section.
        def special_section_priority(description)
          SPECIAL_SECTIONS[description]
        end

        # Get priority for controller actions.
        #
        # @param [String] description The describe block description.
        # @return [Integer]
        # @return [nil] When not a controller action.
        def controller_action_priority(description)
          # Strip the # prefix for controller actions.
          action_name = description.start_with?("#") ? description[1..] : description

          if controller_action?(action_name)
            30 + CONTROLLER_ACTIONS.index(action_name)
          end
        end

        # Get priority for method descriptions.
        #
        # @param [String] description The describe block description.
        # @return [Integer]
        # @return [nil] When not a method description.
        def method_priority(description)
          return 100 if description.start_with?(".")
          return 200 if description.start_with?("#")

          nil
        end

        # Check if description is a controller action.
        #
        # @param [String] description The describe block description.
        # @return [Boolean]
        def controller_action?(description)
          CONTROLLER_ACTIONS.include?(description)
        end

        # Find describe blocks that are out of order.
        #
        # @param [Array<Hash>] blocks The list of describe blocks.
        # @return [Array<Hash>] Blocks that violate ordering.
        def find_ordering_violations(blocks)
          violations = []

          blocks.each_cons(2) do |current, following|
            violations << following if current[:priority] > following[:priority]
          end

          violations.uniq
        end

        # Auto-correct by reordering describe blocks.
        #
        # @param [RuboCop::AST::Corrector] corrector The corrector.
        # @param [Array<Hash>] blocks The list of describe blocks.
        # @return [void]
        def autocorrect(corrector, blocks)
          sorted_blocks = blocks.sort_by { |b| [b[:priority], b[:original_index]] }

          blocks.each_with_index do |block, index|
            sorted_block = sorted_blocks[index]

            next if block == sorted_block

            corrector.replace(block[:node], sorted_block[:node].source)
          end
        end
      end
    end
  end
end
