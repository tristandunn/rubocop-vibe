# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Disallows single character variable names.
      #
      # Single character names tend to obscure intent. The cop flags local
      # variables, instance variables, class variables, method and block
      # parameters, and rescue variables. The leading `@` or `@@` sigil is
      # ignored when measuring length, so `@a` and `@@a` are treated as
      # single character names.
      #
      # Names listed in `AllowedNames` are ignored. The default list contains
      # `_`, which conventionally marks an intentionally unused value.
      #
      # @example
      #   # bad
      #   x = 1
      #   @a = 1
      #   def foo(n); end
      #   [1].each { |i| i }
      #
      #   # good
      #   count = 1
      #   @account = 1
      #   def foo(name); end
      #   [1].each { |index| index }
      #
      # @example AllowedNames: ['_', 'i', 'j']
      #   # good
      #   2.times { |i| i }
      #
      # The block parameter `t` is allowed in files under `db/`, where it is a
      # convention for Rails migrations (e.g. `create_table :users do |t|`).
      class NoSingleCharacterVariableNames < Base
        MIGRATION_BLOCK_VARIABLE = "t"
        MIGRATION_PATH_PATTERN   = %r{(?:\A|/)db/}
        MSG                      = "Avoid single character variable name `%<name>s`."

        # @param node [RuboCop::AST::Node]
        # @return [void]
        def on_arg(node)
          check(node, node.name)
        end
        alias on_blockarg on_arg
        alias on_cvasgn on_arg
        alias on_ivasgn on_arg
        alias on_kwarg on_arg
        alias on_kwoptarg on_arg
        alias on_kwrestarg on_arg
        alias on_lvasgn on_arg
        alias on_optarg on_arg
        alias on_restarg on_arg

        private

        # @return [Array<String>]
        def allowed_names
          @allowed_names ||= Array(cop_config.fetch("AllowedNames", ["_"]))
        end

        # @param node [RuboCop::AST::Node]
        # @param name [Symbol, nil]
        # @return [void]
        def check(node, name)
          return if name.nil?

          bare = name.to_s.sub(/\A@@?/, "")

          return if bare.length != 1
          return if allowed_names.include?(bare)
          return if migration_block_variable?(bare)

          add_offense(node.loc.name, message: format(MSG, name: name))
        end

        # @param bare [String] the variable name without sigils.
        # @return [Boolean]
        def migration_block_variable?(bare)
          bare == MIGRATION_BLOCK_VARIABLE && migration_file?
        end

        # @return [Boolean]
        def migration_file?
          processed_source.file_path.match?(MIGRATION_PATH_PATTERN)
        end
      end
    end
  end
end
