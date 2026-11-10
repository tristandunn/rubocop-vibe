# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Enforces that `rescue` is not used in spec files.
      #
      # Rescuing exceptions in specs can hide failures and hinder debugging.
      # Use `expect { ... }.to raise_error` to assert on exceptions instead.
      #
      # @example
      #   # bad
      #   it "raises an error" do
      #     begin
      #       perform
      #     rescue StandardError
      #       # ignored
      #     end
      #   end
      #
      #   # good
      #   it "raises an error" do
      #     expect { perform }.to raise_error(StandardError)
      #   end
      class NoRescueInSpecs < Base
        include SpecFileHelper

        MSG = "Do not use `rescue` in specs. Use `expect { ... }.to raise_error` instead."

        # Check for rescue clauses in spec files.
        #
        # @param [RuboCop::AST::Node] node The resbody node.
        # @return [void]
        def on_resbody(node)
          if spec_file?
            add_offense(node.loc.keyword)
          end
        end
      end
    end
  end
end
