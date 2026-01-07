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

          groups = group_consecutive_lets(statements)
          groups.each { |group| check_group_alignment(group) }
        end

        # Extract statements from a body node.
        #
        # @param [RuboCop::AST::Node] body The body node.
        # @return [Array<RuboCop::AST::Node>]
        def extract_statements(body)
          if body.begin_type?
            body.children
          else
            [body]
          end
        end

        # Group consecutive let declarations together.
        #
        # @param [Array<RuboCop::AST::Node>] statements The statements.
        # @return [Array<Array<RuboCop::AST::Node>>] Groups of consecutive lets.
        def group_consecutive_lets(statements)
          groups        = []
          current_group = []
          previous_line = nil

          statements.each do |statement|
            current_group, previous_line = process_statement(statement, current_group, previous_line, groups)
          end

          finalize_groups(groups, current_group)
        end

        # Process a single statement for grouping.
        #
        # @param [RuboCop::AST::Node] statement The statement.
        # @param [Array<RuboCop::AST::Node>] current_group The current group.
        # @param [Integer, nil] previous_line The previous line number.
        # @param [Array<Array<RuboCop::AST::Node>>] groups The groups.
        # @return [Array] The updated current_group and previous_line.
        def process_statement(statement, current_group, previous_line, groups)
          if let_declaration?(statement)
            current_group = handle_let(statement, current_group, previous_line, groups)
          else
            save_group_if_valid(groups, current_group)
            current_group = []
          end
          [current_group, statement.loc.last_line]
        end

        # Handle a let declaration.
        #
        # @param [RuboCop::AST::Node] statement The let declaration.
        # @param [Array<RuboCop::AST::Node>] current_group The current group.
        # @param [Integer, nil] previous_line The previous line number.
        # @param [Array<Array<RuboCop::AST::Node>>] groups The groups.
        # @return [Array<RuboCop::AST::Node>] The updated current group.
        def handle_let(statement, current_group, previous_line, groups)
          if previous_line && statement.loc.line - previous_line > 1
            save_group_if_valid(groups, current_group)
            current_group = []
          end
          current_group << statement
          current_group
        end

        # Save group if it has multiple let declarations.
        #
        # @param [Array<Array<RuboCop::AST::Node>>] groups The groups.
        # @param [Array<RuboCop::AST::Node>] group The group to potentially save.
        # @return [void]
        def save_group_if_valid(groups, group)
          groups << group if group.size > 1
        end

        # Finalize groups by adding any remaining valid group.
        #
        # @param [Array<Array<RuboCop::AST::Node>>] groups The groups.
        # @param [Array<RuboCop::AST::Node>] current_group The current group.
        # @return [Array<Array<RuboCop::AST::Node>>] The finalized groups.
        def finalize_groups(groups, current_group)
          save_group_if_valid(groups, current_group)
          groups
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

        # Create a source range between two positions.
        #
        # @param [Integer] start_pos The start position.
        # @param [Integer] end_pos The end position.
        # @return [Parser::Source::Range]
        def range_between(start_pos, end_pos)
          Parser::Source::Range.new(
            processed_source.buffer,
            start_pos,
            end_pos
          )
        end
      end
    end
  end
end
