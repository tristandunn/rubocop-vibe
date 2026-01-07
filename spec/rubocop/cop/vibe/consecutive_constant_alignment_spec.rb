# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::ConsecutiveConstantAlignment, :config do
  describe "#on_class" do
    context "when consecutive constants are not aligned" do
      let(:offense_code) do
        <<~RUBY
          class Character
            MINIMUM_NAME_LENGTH = 3
            MAXIMUM_NAME_LENGTH = 12
            ACTIVE_DURATION = 15
            ^^^^^^^^^^^^^^^ Align consecutive constant assignments at the `=` operator.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class Character
            MINIMUM_NAME_LENGTH = 3
            MAXIMUM_NAME_LENGTH = 12
            ACTIVE_DURATION     = 15
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning constants" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when consecutive constants are already aligned" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Character
            MINIMUM_NAME_LENGTH = 3
            MAXIMUM_NAME_LENGTH = 12
            ACTIVE_DURATION     = 15
          end
        RUBY
      end
    end

    context "when constants are separated by blank lines" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Character
            MINIMUM_NAME_LENGTH = 3
            MAXIMUM_NAME_LENGTH = 12

            ACTIVE_DURATION = 15
          end
        RUBY
      end
    end

    context "when there is only one constant" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Character
            MINIMUM_NAME_LENGTH = 3
          end
        RUBY
      end
    end

    context "when constants are in separate groups" do
      let(:offense_code) do
        <<~RUBY
          class Character
            MIN = 3
            ^^^ Align consecutive constant assignments at the `=` operator.
            MAXIMUM = 12

            THROTTLE_LIMIT = 10
            ^^^^^^^^^^^^^^ Align consecutive constant assignments at the `=` operator.
            THROTTLE_PERIOD = 5
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class Character
            MIN     = 3
            MAXIMUM = 12

            THROTTLE_LIMIT  = 10
            THROTTLE_PERIOD = 5
          end
        RUBY
      end

      it "registers offenses for each misaligned group" do
        expect_offense(offense_code)
      end

      it "autocorrects each group independently" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when non-constant statements break up constants" do
      it "does not register an offense for separated constants" do
        expect_no_offenses(<<~RUBY)
          class Character
            MINIMUM = 3

            belongs_to :account

            MAXIMUM = 12
          end
        RUBY
      end
    end

    context "when there are two consecutive constants" do
      let(:offense_code) do
        <<~RUBY
          class Character
            A = 1
            ^ Align consecutive constant assignments at the `=` operator.
            BB = 2
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class Character
            A  = 1
            BB = 2
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning constants" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when class has no body" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class EmptyClass
          end
        RUBY
      end
    end
  end

  describe "#on_module" do
    context "when consecutive constants in a module are not aligned" do
      let(:offense_code) do
        <<~RUBY
          module Commands
            PREFIX = "Commands::"
            ^^^^^^ Align consecutive constant assignments at the `=` operator.
            THROTTLE_LIMIT = 10
            ^^^^^^^^^^^^^^ Align consecutive constant assignments at the `=` operator.
            THROTTLE_PERIOD = 5
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          module Commands
            PREFIX          = "Commands::"
            THROTTLE_LIMIT  = 10
            THROTTLE_PERIOD = 5
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning constants" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when module has no body" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          module EmptyModule
          end
        RUBY
      end
    end
  end

  describe "edge cases" do
    context "when constants have multi-line RHS" do
      it "does not register an offense (only single-line constants are aligned)" do
        expect_no_offenses(<<~RUBY)
          class Character
            OFFSETS = {
              north: 1
            }.freeze
            DEFAULT_VALUE = 0
          end
        RUBY
      end
    end

    context "when autocorrecting ensures at least one space" do
      let(:offense_code) do
        <<~RUBY
          class Character
            VERY_LONG_CONSTANT_NAME = 1
            X = 2
            ^ Align consecutive constant assignments at the `=` operator.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class Character
            VERY_LONG_CONSTANT_NAME = 1
            X                       = 2
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects with proper spacing" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with regex constants" do
      let(:offense_code) do
        <<~RUBY
          class Account
            EMAIL_MATCHER = /\\A[^@]+@[^@]+\\z/
            ^^^^^^^^^^^^^ Align consecutive constant assignments at the `=` operator.
            MAXIMUM_EMAIL_LENGTH = 255
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class Account
            EMAIL_MATCHER        = /\\A[^@]+@[^@]+\\z/
            MAXIMUM_EMAIL_LENGTH = 255
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning constants" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with frozen array constants" do
      it "does not register frozen arrays correctly" do
        expect_no_offenses(<<~RUBY)
          class Character
            VALID_STATES = %w(active inactive).freeze
            DIRECTIONS   = %i(north south east west).freeze
          end
        RUBY
      end
    end
  end
end
