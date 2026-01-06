# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::NoUnlessGuardClause, :config do
  describe "#on_if" do
    context "when using if guard clause" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def multi_example
            return if valid?

            4
          end
        RUBY
      end
    end

    context "when using unless guard clause with implicit nil return" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          def unless_example
            return unless valid?
            ^^^^^^^^^^^^^^^^^^^^ Use positive `if` condition instead of `unless` for guard clauses.

            4
          end
        RUBY

        expect_correction(<<~RUBY)
          def unless_example
            if valid?
              4
            end
          end
        RUBY
      end
    end

    context "when using unless guard clause with explicit return value" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          def unless_example
            return 32 unless valid?
            ^^^^^^^^^^^^^^^^^^^^^^^ Use positive `if` condition instead of `unless` for guard clauses.

            4
          end
        RUBY

        expect_correction(<<~RUBY)
          def unless_example
            if valid?
              4
            else
              32
            end
          end
        RUBY
      end
    end

    context "when using regular if/else blocks" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def single_example
            if new?
              4
            else
              32
            end
          end
        RUBY
      end
    end

    context "when using ternary operator in method" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def tern_example
            variable = old? ? 13 : 7

            if new?
              4
            else
              variable
            end
          end
        RUBY
      end
    end

    context "when unless is not a guard clause" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def example
            x = 4 unless valid?
          end
        RUBY
      end
    end

    context "when unless guard clause is at the end of method" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def example
            return unless valid?
          end
        RUBY
      end
    end

    context "when using unless in a non-modifier form" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def example
            unless valid?
              return
            end

            4
          end
        RUBY
      end
    end

    context "when using multiple unless guard clauses" do
      it "does not register an offense (keeps guard sequence together)" do
        expect_no_offenses(<<~RUBY)
          def example
            return unless valid?
            return unless active?

            4
          end
        RUBY
      end
    end

    context "when guard clause has complex condition" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          def example
            return unless valid? && active?
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use positive `if` condition instead of `unless` for guard clauses.

            4
          end
        RUBY

        expect_correction(<<~RUBY)
          def example
            if valid? && active?
              4
            end
          end
        RUBY
      end
    end

    context "when guard clause has method call with arguments" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          def example
            return unless valid_for?(user)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use positive `if` condition instead of `unless` for guard clauses.

            4
          end
        RUBY

        expect_correction(<<~RUBY)
          def example
            if valid_for?(user)
              4
            end
          end
        RUBY
      end
    end

    context "when guard clause returns complex expression" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          def example
            return user.id unless valid?
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use positive `if` condition instead of `unless` for guard clauses.

            4
          end
        RUBY

        expect_correction(<<~RUBY)
          def example
            if valid?
              4
            else
              user.id
            end
          end
        RUBY
      end
    end

    context "when there are multiple statements after guard clause" do
      it "registers an offense and autocorrects preserving all statements" do
        expect_offense(<<~RUBY)
          def example
            return unless valid?
            ^^^^^^^^^^^^^^^^^^^^ Use positive `if` condition instead of `unless` for guard clauses.

            x = 4
            y = 5
            x + y
          end
        RUBY

        expect_correction(<<~RUBY)
          def example
            if valid?
              x = 4
              y = 5
              x + y
            end
          end
        RUBY
      end
    end

    context "when guard clause returns array literal" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          def example
            return [1, 2, 3] unless valid?
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use positive `if` condition instead of `unless` for guard clauses.

            4
          end
        RUBY

        expect_correction(<<~RUBY)
          def example
            if valid?
              4
            else
              [1, 2, 3]
            end
          end
        RUBY
      end
    end

    context "when guard clause returns hash literal" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          def example
            return { a: 1 } unless valid?
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use positive `if` condition instead of `unless` for guard clauses.

            4
          end
        RUBY

        expect_correction(<<~RUBY)
          def example
            if valid?
              4
            else
              { a: 1 }
            end
          end
        RUBY
      end
    end

    context "when guard clause is inside a class method" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          class Example
            def self.check
              return unless valid?
              ^^^^^^^^^^^^^^^^^^^^ Use positive `if` condition instead of `unless` for guard clauses.

              4
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          class Example
            def self.check
              if valid?
                4
              end
            end
          end
        RUBY
      end
    end

    context "when unless is not used with return" do
      it "does not register an offense for break" do
        expect_no_offenses(<<~RUBY)
          def example
            break unless valid?

            4
          end
        RUBY
      end

      it "does not register an offense for next" do
        expect_no_offenses(<<~RUBY)
          def example
            next unless valid?

            4
          end
        RUBY
      end
    end

    context "when unless guard clause is in a method with only one expression" do
      it "does not register an offense (no begin block)" do
        expect_no_offenses(<<~RUBY)
          def example
            return unless valid?
          end
        RUBY
      end
    end

    context "when unless guard clause is in a block with only one expression" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          items.each do |item|
            return unless item.valid?
          end
        RUBY
      end
    end

    context "when using if guard clause followed by unless guard clause" do
      it "does not register an offense (keeps guard sequence together)" do
        expect_no_offenses(<<~RUBY)
          def example
            return if invalid?
            return unless valid?

            4
          end
        RUBY
      end
    end

    context "when guard clause with explicit nil" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          def example
            return nil unless valid?
            ^^^^^^^^^^^^^^^^^^^^^^^^ Use positive `if` condition instead of `unless` for guard clauses.

            4
          end
        RUBY

        expect_correction(<<~RUBY)
          def example
            if valid?
              4
            else
              nil
            end
          end
        RUBY
      end
    end

    context "when guard clause with boolean return" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          def example
            return false unless valid?
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ Use positive `if` condition instead of `unless` for guard clauses.

            true
          end
        RUBY

        expect_correction(<<~RUBY)
          def example
            if valid?
              true
            else
              false
            end
          end
        RUBY
      end
    end

    context "when preceded by a non-modifier unless" do
      it "registers an offense for the second guard clause" do
        expect_offense(<<~RUBY)
          def example
            unless invalid?
              return
            end

            return unless valid?
            ^^^^^^^^^^^^^^^^^^^^ Use positive `if` condition instead of `unless` for guard clauses.

            4
          end
        RUBY

        expect_correction(<<~RUBY)
          def example
            unless invalid?
              return
            end

            if valid?
              4
            end
          end
        RUBY
      end
    end

    context "when preceded by a regular assignment" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def example
            x = 1

            return unless valid?
            ^^^^^^^^^^^^^^^^^^^^ Use positive `if` condition instead of `unless` for guard clauses.

            x + 1
          end
        RUBY

        expect_correction(<<~RUBY)
          def example
            x = 1

            if valid?
              x + 1
            end
          end
        RUBY
      end
    end

    context "when remaining code is a conditional (would create nesting)" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def example
            return unless first_arg

            if first_arg.str_type?
              first_arg.value
            elsif first_arg.sym_type?
              first_arg.value.to_s
            end
          end
        RUBY
      end
    end

    context "when remaining code is a case statement (would create nesting)" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def example
            return unless value

            case value
            when :foo
              1
            when :bar
              2
            end
          end
        RUBY
      end
    end
  end
end
