# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces alignment of consecutive `let` declarations at the `{` brace.
      #
      # Consecutive `let` declarations (with no blank lines between) should align their
      # `{` braces for better readability. Groups are broken by blank lines or non-let
      # statements.
      #
      # @example
      #   # bad
      #   let(:character) { instance_double(Character) }
      #   let(:damage) { 1 }
      #   let(:instance) { described_class.new }
      #
      #   # good
      #   let(:character) { instance_double(Character) }
      #   let(:damage)    { 1 }
      #   let(:instance)  { described_class.new }
      #
      #   # good - blank line breaks the group
      #   let(:user)      { create(:user) }
      #   let(:character) { create(:character) }
      #
      #   let(:service) { Users::Activate.new }  # Separate group, not aligned
      class ConsecutiveLetAlignment < Base
        extend AutoCorrector
        include SpecFileHelper
        include AlignmentHelpers

        MSG = "Align consecutive `let` declarations at the `{` brace."

        # @!method let_declaration?(node)
        #   Check if node is a let/let! declaration.
        def_node_matcher :let_declaration?, <<~PATTERN
          (block (send nil? {:let :let!} (sym _)) ...)
        PATTERN

        # Check describe/context blocks for let alignment.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [void]
        def on_block(node)
          return unless spec_file?
          return unless describe_or_context?(node)
          return unless node.body

          check_lets_in_body(node.body)
        end
        alias on_numblock on_block

        private

        # Check if block is a describe or context block.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [Boolean]
        def describe_or_context?(node)
          node.send_node && %i(describe context).include?(node.method_name)
        end

        # Check let declarations in a body node.
        #
        # @param [RuboCop::AST::Node] body The body node.
        # @return [void]
        def check_lets_in_body(body)
          statements = extract_statements(body)

          return if statements.size < 2

          groups = group_consecutive_statements(statements) { |s| let_declaration?(s) }

          groups.each { |group| check_group_alignment(group) }
        end

        # Check alignment for a group of let declarations.
        #
        # @param [Array<RuboCop::AST::Node>] group The let group.
        # @return [void]
        def check_group_alignment(group)
          columns       = group.map { |let| let.loc.begin.column }
          target_column = columns.max

          group.each do |let|
            current_column = let.loc.begin.column

            next if current_column == target_column

            add_offense(let.send_node) do |corrector|
              autocorrect_alignment(corrector, let, target_column)
            end
          end
        end

        # Auto-correct the alignment of a let declaration.
        #
        # @param [RuboCop::AST::Corrector] corrector The corrector.
        # @param [RuboCop::AST::Node] let The let block node.
        # @param [Integer] target_column The target column for alignment.
        # @return [void]
        def autocorrect_alignment(corrector, let, target_column)
          send_node    = let.send_node
          send_end     = send_node.source_range.end_pos
          brace_start  = let.loc.begin.begin_pos
          total_spaces = calculate_total_spaces(let, target_column)

          corrector.replace(
            range_between(send_end, brace_start),
            " " * total_spaces
          )
        end

        # Calculate total spaces needed for alignment.
        #
        # @param [RuboCop::AST::Node] let The let block node.
        # @param [Integer] target_column The target column for alignment.
        # @return [Integer] The number of spaces (minimum 1).
        def calculate_total_spaces(let, target_column)
          current_column = let.loc.begin.column
          current_spaces = let.loc.begin.begin_pos - let.send_node.source_range.end_pos
          spaces_needed  = target_column - current_column

          [1, current_spaces + spaces_needed].max
        end
      end
    end
  end
end
