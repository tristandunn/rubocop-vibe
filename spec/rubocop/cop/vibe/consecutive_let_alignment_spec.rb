# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::ConsecutiveLetAlignment, :config do
  describe "#on_block" do
    context "when consecutive let declarations are not aligned" do
      let(:offense_code) do
        <<~RUBY
          describe Character do
            let(:character) { instance_double(Character) }
            let(:damage) { 1 }
            ^^^^^^^^^^^^ Align consecutive `let` declarations at the `{` brace.
            let(:instance) { described_class.new }
            ^^^^^^^^^^^^^^ Align consecutive `let` declarations at the `{` brace.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          describe Character do
            let(:character) { instance_double(Character) }
            let(:damage)    { 1 }
            let(:instance)  { described_class.new }
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/character_spec.rb")
      end

      it "autocorrects by aligning let declarations" do
        expect_offense(offense_code, "spec/models/character_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when consecutive let declarations are already aligned" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/character_spec.rb")
          describe Character do
            let(:character) { instance_double(Character) }
            let(:damage)    { 1 }
            let(:instance)  { described_class.new }
          end
        RUBY
      end
    end

    context "when let declarations are separated by blank lines" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/character_spec.rb")
          describe Character do
            let(:character) { instance_double(Character) }
            let(:damage)    { 1 }

            let(:instance) { described_class.new }
          end
        RUBY
      end
    end

    context "when there is only one let declaration" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/character_spec.rb")
          describe Character do
            let(:character) { instance_double(Character) }
          end
        RUBY
      end
    end

    context "when let declarations are in separate groups" do
      let(:offense_code) do
        <<~RUBY
          describe Character do
            let(:user) { create(:user) }
            ^^^^^^^^^^ Align consecutive `let` declarations at the `{` brace.
            let(:character) { create(:character) }

            let(:service) { Users::Activate.new }
            ^^^^^^^^^^^^^ Align consecutive `let` declarations at the `{` brace.
            let(:activation) { service.call }
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          describe Character do
            let(:user)      { create(:user) }
            let(:character) { create(:character) }

            let(:service)    { Users::Activate.new }
            let(:activation) { service.call }
          end
        RUBY
      end

      it "registers offenses for each misaligned group" do
        expect_offense(offense_code, "spec/models/character_spec.rb")
      end

      it "autocorrects each group independently" do
        expect_offense(offense_code, "spec/models/character_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when non-let statements break up let declarations" do
      it "does not register an offense for separated let declarations" do
        expect_no_offenses(<<~RUBY, "spec/models/character_spec.rb")
          describe Character do
            let(:user) { create(:user) }

            before { user.activate }

            let(:character) { create(:character) }
          end
        RUBY
      end
    end

    context "when there are two consecutive let declarations" do
      let(:offense_code) do
        <<~RUBY
          describe Character do
            let(:a) { 1 }
            ^^^^^^^ Align consecutive `let` declarations at the `{` brace.
            let(:bb) { 2 }
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          describe Character do
            let(:a)  { 1 }
            let(:bb) { 2 }
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/character_spec.rb")
      end

      it "autocorrects by aligning let declarations" do
        expect_offense(offense_code, "spec/models/character_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when file is not a spec file" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "app/models/character.rb")
          describe Character do
            let(:user) { create(:user) }
            let(:character) { create(:character) }
          end
        RUBY
      end
    end

    context "when describe block has no body" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/character_spec.rb")
          describe Character do
          end
        RUBY
      end
    end

    context "with let! declarations" do
      let(:offense_code) do
        <<~RUBY
          describe Character do
            let!(:user) { create(:user) }
            ^^^^^^^^^^^ Align consecutive `let` declarations at the `{` brace.
            let!(:character) { create(:character) }
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          describe Character do
            let!(:user)      { create(:user) }
            let!(:character) { create(:character) }
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/character_spec.rb")
      end

      it "autocorrects by aligning let! declarations" do
        expect_offense(offense_code, "spec/models/character_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "with mixed let and let! declarations" do
      let(:offense_code) do
        <<~RUBY
          describe Character do
            let(:user) { create(:user) }
            ^^^^^^^^^^ Align consecutive `let` declarations at the `{` brace.
            let!(:character) { create(:character) }
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          describe Character do
            let(:user)       { create(:user) }
            let!(:character) { create(:character) }
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/character_spec.rb")
      end

      it "autocorrects by aligning both let and let! declarations" do
        expect_offense(offense_code, "spec/models/character_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "with nested describe blocks" do
      let(:offense_code) do
        <<~RUBY
          describe Character do
            describe "#call" do
              let(:user) { create(:user) }
              ^^^^^^^^^^ Align consecutive `let` declarations at the `{` brace.
              let(:character) { create(:character) }
            end
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          describe Character do
            describe "#call" do
              let(:user)      { create(:user) }
              let(:character) { create(:character) }
            end
          end
        RUBY
      end

      it "registers an offense in nested describe blocks" do
        expect_offense(offense_code, "spec/models/character_spec.rb")
      end

      it "autocorrects nested describe blocks" do
        expect_offense(offense_code, "spec/models/character_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "with context blocks" do
      let(:offense_code) do
        <<~RUBY
          describe Character do
            context "when active" do
              let(:user) { create(:user) }
              ^^^^^^^^^^ Align consecutive `let` declarations at the `{` brace.
              let(:character) { create(:character) }
            end
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          describe Character do
            context "when active" do
              let(:user)      { create(:user) }
              let(:character) { create(:character) }
            end
          end
        RUBY
      end

      it "registers an offense in context blocks" do
        expect_offense(offense_code, "spec/models/character_spec.rb")
      end

      it "autocorrects context blocks" do
        expect_offense(offense_code, "spec/models/character_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when autocorrecting ensures at least one space" do
      let(:offense_code) do
        <<~RUBY
          describe Character do
            let(:very_long_variable_name) { 1 }
            let(:x) { 2 }
            ^^^^^^^ Align consecutive `let` declarations at the `{` brace.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          describe Character do
            let(:very_long_variable_name) { 1 }
            let(:x)                       { 2 }
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/character_spec.rb")
      end

      it "autocorrects with proper spacing" do
        expect_offense(offense_code, "spec/models/character_spec.rb")

        expect_correction(corrected_code)
      end
    end
  end
end
