# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::ConsecutiveAssignmentAlignment, :config do
  describe "#on_def" do
    context "when consecutive assignments are not aligned" do
      let(:offense_code) do
        <<~RUBY
          def setup
            user = create(:user)
            ^^^^ Align consecutive assignments at the = operator.
            character = create(:character)
            input = "test"
            ^^^^^ Align consecutive assignments at the = operator.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def setup
            user      = create(:user)
            character = create(:character)
            input     = "test"
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning assignments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when consecutive assignments are already aligned" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def setup
            user      = create(:user)
            character = create(:character)
            input     = "test"
          end
        RUBY
      end
    end

    context "when assignments are separated by blank lines" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def setup
            user      = create(:user)
            character = create(:character)

            service = Users::Activate.new
          end
        RUBY
      end
    end

    context "when there is only one assignment" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def setup
            user = create(:user)
          end
        RUBY
      end
    end

    context "when assignments are in separate groups" do
      let(:offense_code) do
        <<~RUBY
          def setup
            user = create(:user)
            ^^^^ Align consecutive assignments at the = operator.
            character = create(:character)

            service = Users::Activate.new
            ^^^^^^^ Align consecutive assignments at the = operator.
            activation = service.call
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def setup
            user      = create(:user)
            character = create(:character)

            service    = Users::Activate.new
            activation = service.call
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

    context "when non-assignment statements break up assignments" do
      it "does not register an offense for separated assignments" do
        expect_no_offenses(<<~RUBY)
          def setup
            user = create(:user)
            process_user(user)
            character = create(:character)
          end
        RUBY
      end
    end

    context "when there are two consecutive assignments" do
      let(:offense_code) do
        <<~RUBY
          def setup
            a = 1
            ^ Align consecutive assignments at the = operator.
            bb = 2
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def setup
            a  = 1
            bb = 2
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning assignments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end
  end

  describe "#on_defs" do
    context "when consecutive assignments in a singleton method are not aligned" do
      let(:offense_code) do
        <<~RUBY
          def self.setup
            user = create(:user)
            ^^^^ Align consecutive assignments at the = operator.
            character = create(:character)
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def self.setup
            user      = create(:user)
            character = create(:character)
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning assignments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end
  end

  describe "#on_block" do
    context "when consecutive assignments in a block are not aligned" do
      let(:offense_code) do
        <<~RUBY
          RSpec.describe User do
            it "creates records" do
              user = create(:user)
              ^^^^ Align consecutive assignments at the = operator.
              character = create(:character)
            end
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          RSpec.describe User do
            it "creates records" do
              user      = create(:user)
              character = create(:character)
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning assignments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when block has no body" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          items.each { |item| }
        RUBY
      end
    end

    context "when using numbered block parameters" do
      let(:offense_code) do
        <<~RUBY
          items.map do
            user = _1
            ^^^^ Align consecutive assignments at the = operator.
            character = _2
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          items.map do
            user      = _1
            character = _2
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning assignments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end
  end

  describe "edge cases" do
    context "when assignments have multi-line RHS" do
      let(:offense_code) do
        <<~RUBY
          def setup
            user = create(
            ^^^^ Align consecutive assignments at the = operator.
              :user,
              name: "Test"
            )
            character = create(:character)
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def setup
            user      = create(
              :user,
              name: "Test"
            )
            character = create(:character)
          end
        RUBY
      end

      it "registers an offense on the shorter variable name" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning assignments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when multi-line RHS creates a gap" do
      it "treats all consecutive assignments as same group despite multi-line RHS" do
        expect_offense(<<~RUBY)
          def setup
            a = foo
            ^ Align consecutive assignments at the = operator.
            bb = bar(
            ^^ Align consecutive assignments at the = operator.
              baz
            )
            ccc = qux
          end
        RUBY
      end
    end

    context "with instance variable assignments" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def setup
            @user = create(:user)
            @character = create(:character)
          end
        RUBY
      end
    end

    context "with class variable assignments" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def setup
            @@user = create(:user)
            @@character = create(:character)
          end
        RUBY
      end
    end

    context "with global variable assignments" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def setup
            $user = create(:user)
            $character = create(:character)
          end
        RUBY
      end
    end

    context "with operator assignments" do
      it "does not register an offense for ||=" do
        expect_no_offenses(<<~RUBY)
          def setup
            user ||= create(:user)
            character ||= create(:character)
          end
        RUBY
      end

      it "does not register an offense for +=" do
        expect_no_offenses(<<~RUBY)
          def setup
            count += 1
            total += amount
          end
        RUBY
      end
    end

    context "with multiple assignment (destructuring)" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def setup
            a, b = values
            first, second, third = other_values
          end
        RUBY
      end
    end

    context "with mixed local and instance variable assignments" do
      it "instance variable breaks the group so no alignment needed" do
        expect_no_offenses(<<~RUBY)
          def setup
            user = create(:user)
            @user = user
            character = create(:character)
          end
        RUBY
      end

      it "aligns consecutive local variables around instance variable" do
        expect_offense(<<~RUBY)
          def setup
            a = 1
            ^ Align consecutive assignments at the = operator.
            bb = 2
            @instance = value
            ccc = 3
            ^^^ Align consecutive assignments at the = operator.
            dddd = 4
          end
        RUBY
      end
    end

    context "with assignments inside conditionals" do
      it "does not check nested assignments" do
        expect_no_offenses(<<~RUBY)
          def setup
            if condition
              user = create(:user)
              character = create(:character)
            end
          end
        RUBY
      end
    end

    context "with assignments inside rescue blocks" do
      it "does not check nested assignments" do
        expect_no_offenses(<<~RUBY)
          def setup
            user = create(:user)
          rescue StandardError
            error = "failed"
            message = "something went wrong"
          end
        RUBY
      end
    end

    context "with heredoc assignments" do
      it "handles heredocs correctly" do
        expect_offense(<<~RUBY)
          def setup
            short = "value"
            ^^^^^ Align consecutive assignments at the = operator.
            longer_name = <<~TEXT
              Some text here
            TEXT
          end
        RUBY
      end
    end
  end
end
