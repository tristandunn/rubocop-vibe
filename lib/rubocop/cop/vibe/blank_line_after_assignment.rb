# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces a blank line after variable assignments when followed by other code.
      #
      # Variable assignments should be visually separated from the code that uses them.
      # Consecutive assignments are allowed without blank lines between them, but there
      # should be a blank line before non-assignment code.
      #
      # @example
      #   # bad
      #   deleted_count = delete_batch
      #   break if deleted_count < BATCH_SIZE
      #
      #   # good
      #   deleted_count = delete_batch
      #
      #   break if deleted_count < BATCH_SIZE
      #
      #   # good - consecutive assignments don't need blank lines
      #   user = find_user
      #   account = user.account
      #
      #   process(user, account)
      #
      #   # good - next line uses the assigned variable
      #   forwarded = request.headers["X-Forwarded-For"]
      #   forwarded.to_s.split(",").first.to_s.strip.presence
      #
      #   # good - consecutive FactoryBot calls
      #   website   = create(:website)
      #   page_view = create(:page_view, website: website)
      #   create(:page_view, website: website)
      class BlankLineAfterAssignment < Base
        extend AutoCorrector

        MSG = "Add a blank line after variable assignment."

        FACTORY_BOT_METHODS = %i(
          create build build_stubbed attributes_for
          create_list build_list build_stubbed_list attributes_for_list
        ).freeze

        # Check block nodes for assignment statements.
        #
        # @param [RuboCop::AST::Node] node The block node.
        # @return [void]
        def on_block(node)
          if node.body
            check_body(node.body)
          end
        end
        alias on_numblock on_block

        # Check method definitions for assignment statements.
        #
        # @param [RuboCop::AST::Node] node The def node.
        # @return [void]
        def on_def(node)
          if node.body
            check_body(node.body)
          end
        end
        alias on_defs on_def

        private

        # Check the body for missing blank lines after assignments.
        #
        # @param [RuboCop::AST::Node] body The body node.
        # @return [void]
        def check_body(body)
          statements = extract_statements(body)

          return if statements.size < 2

          statements.each_cons(2) do |current, following|
            check_statement_pair(current, following)
          end
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

        # Check a pair of statements for missing blank line after assignment.
        #
        # @param [RuboCop::AST::Node] current The current statement.
        # @param [RuboCop::AST::Node] following The following statement.
        # @return [void]
        def check_statement_pair(current, following)
          return unless assignment?(current)
          return if assignment?(following)
          return if blank_line_between?(current, following)
          return if following_uses_assigned_variable?(current, following)
          return if consecutive_factory_bot_calls?(current, following)

          add_offense(following) do |corrector|
            corrector.insert_after(current, "\n")
          end
        end

        # Check if both statements are FactoryBot calls.
        #
        # @param [RuboCop::AST::Node] assignment The assignment node.
        # @param [RuboCop::AST::Node] following The following statement.
        # @return [Boolean]
        def consecutive_factory_bot_calls?(assignment, following)
          factory_bot_call?(assignment_value(assignment)) && factory_bot_call?(following)
        end

        # Get the value being assigned.
        #
        # @param [RuboCop::AST::Node] node The assignment node.
        # @return [RuboCop::AST::Node, nil]
        def assignment_value(node)
          node.children.last
        end

        # Check if a node is a FactoryBot method call.
        #
        # @param [RuboCop::AST::Node] node The node to check.
        # @return [Boolean]
        def factory_bot_call?(node)
          node.send_type? && FACTORY_BOT_METHODS.include?(node.method_name)
        end

        # Check if the following statement starts with the assigned variable.
        #
        # @param [RuboCop::AST::Node] assignment The assignment node.
        # @param [RuboCop::AST::Node] following The following statement.
        # @return [Boolean]
        def following_uses_assigned_variable?(assignment, following)
          var_name = assigned_variable_name(assignment)

          return false unless var_name

          receiver = leftmost_receiver(following)

          return false unless receiver

          receiver.lvar_type? && receiver.children.first == var_name
        end

        # Get the variable name from an assignment node.
        #
        # @param [RuboCop::AST::Node] node The assignment node.
        # @return [Symbol, nil]
        def assigned_variable_name(node)
          return node.children.first if node.lvasgn_type?

          target = node.children.first

          if target.lvasgn_type?
            target.children.first
          end
        end

        # Get the leftmost receiver in a method chain.
        #
        # @param [RuboCop::AST::Node] node The node to check.
        # @return [RuboCop::AST::Node, nil]
        def leftmost_receiver(node)
          return node if node.lvar_type?
          return unless node.send_type?

          current = node

          current = current.receiver while current.send_type? && current.receiver

          current
        end

        # Check if a node is a variable assignment.
        #
        # @param [RuboCop::AST::Node] node The node to check.
        # @return [Boolean]
        def assignment?(node)
          node.type?(:lvasgn, :op_asgn, :or_asgn, :and_asgn)
        end

        # Check if there's a blank line between two statements.
        #
        # @param [RuboCop::AST::Node] previous_node The previous statement.
        # @param [RuboCop::AST::Node] current_node The current statement.
        # @return [Boolean]
        def blank_line_between?(previous_node, current_node)
          current_node.loc.line - previous_node.loc.last_line > 1
        end
      end
    end
  end
end
