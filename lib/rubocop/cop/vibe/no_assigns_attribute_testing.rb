# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces that controller specs only test assignment identity, not attributes or associations.
      #
      # Testing model attributes or associations from assigns is considered bad practice
      # because it couples the controller spec to the model implementation.
      # Controller specs should only verify that the correct object is assigned,
      # not test the object's internal state or associations.
      #
      # @example
      #   # bad
      #   expect(assigns(:user).email).to eq('test@example.com')
      #   expect(assigns(:user).posts.count).to eq(5)
      #   expect(assigns(:post).author.name).to eq('John')
      #
      #   # good
      #   expect(assigns(:user)).to eq(user)
      #   expect(assigns(:post)).to eq(post)
      #
      class NoAssignsAttributeTesting < Base
        include SpecFileHelper

        MSG = "Do not test attributes or associations from assigns. " \
              "Only test the assignment itself: `expect(assigns(:var)).to eq(object)`"

        CONTROLLER_SPEC_PATTERN = %r{spec/controllers/.*_spec\.rb}

        # Matches assigns(:variable).method_call patterns.
        # @!method assigns_with_method?(node)
        def_node_matcher :assigns_with_method?, <<~PATTERN
          (send
            (send nil? :assigns ...)
            $_)
        PATTERN

        # Checks if assigns is being called with a method in controller specs.
        #
        # @param node [RuboCop::AST::SendNode] the node being checked.
        # @return [void]
        def on_send(node)
          return unless controller_spec_file?
          return unless assigns_with_method?(node)

          add_offense(node.loc.selector)
        end
        alias on_csend on_send

        private

        # Checks if the current file is a controller spec.
        #
        # @return [Boolean] true if the file is a controller spec.
        def controller_spec_file?
          processed_source.file_path.match?(CONTROLLER_SPEC_PATTERN)
        end
      end
    end
  end
end
