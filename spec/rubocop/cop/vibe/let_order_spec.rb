# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::LetOrder, :config do
  describe "#on_block" do
    context "when consecutive let declarations are not alphabetically ordered" do
      let(:offense_code) do
        <<~RUBY
          describe Character do
            let(:subcategory) { create(:category, :subcategory) }
            let(:budget)      { subcategory.budget }
            ^^^^^^^^^^^^ Order consecutive `let` declarations alphabetically.
            let(:category)    { subcategory.parent }
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          describe Character do
            let(:budget)      { subcategory.budget }
            let(:category)    { subcategory.parent }
            let(:subcategory) { create(:category, :subcategory) }
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/character_spec.rb")
      end

      it "autocorrects by reordering let declarations" do
        expect_offense(offense_code, "spec/models/character_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when consecutive let declarations are already alphabetically ordered" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/character_spec.rb")
          describe Character do
            let(:apple)  { create(:apple) }
            let(:banana) { create(:banana) }
            let(:cherry) { create(:cherry) }
          end
        RUBY
      end
    end

    context "when let declarations are separated by blank lines" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/character_spec.rb")
          describe Character do
            let(:zebra) { create(:zebra) }

            let(:apple) { create(:apple) }
          end
        RUBY
      end
    end

    context "when there is only one let declaration" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/character_spec.rb")
          describe Character do
            let(:character) { create(:character) }
          end
        RUBY
      end
    end

    context "when let declarations are in separate groups" do
      let(:offense_code) do
        <<~RUBY
          describe Character do
            let(:zebra) { create(:zebra) }
            let(:apple) { create(:apple) }
            ^^^^^^^^^^^ Order consecutive `let` declarations alphabetically.

            let(:yellow) { create(:yellow) }
            let(:blue)   { create(:blue) }
            ^^^^^^^^^^ Order consecutive `let` declarations alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          describe Character do
            let(:apple) { create(:apple) }
            let(:zebra) { create(:zebra) }

            let(:blue)   { create(:blue) }
            let(:yellow) { create(:yellow) }
          end
        RUBY
      end

      it "registers offenses for each unordered group" do
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
            let(:zebra) { create(:zebra) }

            before { zebra.activate }

            let(:apple) { create(:apple) }
          end
        RUBY
      end
    end

    context "when there are two consecutive let declarations" do
      let(:offense_code) do
        <<~RUBY
          describe Character do
            let(:bb) { 2 }
            let(:aa) { 1 }
            ^^^^^^^^ Order consecutive `let` declarations alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          describe Character do
            let(:aa) { 1 }
            let(:bb) { 2 }
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/character_spec.rb")
      end

      it "autocorrects by reordering let declarations" do
        expect_offense(offense_code, "spec/models/character_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when file is not a spec file" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "app/models/character.rb")
          describe Character do
            let(:zebra) { create(:zebra) }
            let(:apple) { create(:apple) }
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
            let!(:zebra) { create(:zebra) }
            let!(:apple) { create(:apple) }
            ^^^^^^^^^^^^ Order consecutive `let` declarations alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          describe Character do
            let!(:apple) { create(:apple) }
            let!(:zebra) { create(:zebra) }
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/character_spec.rb")
      end

      it "autocorrects by reordering let! declarations" do
        expect_offense(offense_code, "spec/models/character_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "with mixed let and let! declarations" do
      let(:offense_code) do
        <<~RUBY
          describe Character do
            let!(:zebra) { create(:zebra) }
            let(:apple)  { create(:apple) }
            ^^^^^^^^^^^ Order consecutive `let` declarations alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          describe Character do
            let(:apple)  { create(:apple) }
            let!(:zebra) { create(:zebra) }
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/character_spec.rb")
      end

      it "autocorrects by reordering both let and let! declarations" do
        expect_offense(offense_code, "spec/models/character_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "with nested describe blocks" do
      let(:offense_code) do
        <<~RUBY
          describe Character do
            describe "#call" do
              let(:zebra) { create(:zebra) }
              let(:apple) { create(:apple) }
              ^^^^^^^^^^^ Order consecutive `let` declarations alphabetically.
            end
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          describe Character do
            describe "#call" do
              let(:apple) { create(:apple) }
              let(:zebra) { create(:zebra) }
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
              let(:zebra) { create(:zebra) }
              let(:apple) { create(:apple) }
              ^^^^^^^^^^^ Order consecutive `let` declarations alphabetically.
            end
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          describe Character do
            context "when active" do
              let(:apple) { create(:apple) }
              let(:zebra) { create(:zebra) }
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

    context "with multiple violations in the same group" do
      let(:offense_code) do
        <<~RUBY
          describe Character do
            let(:delta) { 4 }
            let(:charlie) { 3 }
            ^^^^^^^^^^^^^ Order consecutive `let` declarations alphabetically.
            let(:bravo) { 2 }
            ^^^^^^^^^^^ Order consecutive `let` declarations alphabetically.
            let(:alpha) { 1 }
            ^^^^^^^^^^^ Order consecutive `let` declarations alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          describe Character do
            let(:alpha) { 1 }
            let(:bravo) { 2 }
            let(:charlie) { 3 }
            let(:delta) { 4 }
          end
        RUBY
      end

      it "registers an offense for each out-of-order let" do
        expect_offense(offense_code, "spec/models/character_spec.rb")
      end

      it "autocorrects all declarations" do
        expect_offense(offense_code, "spec/models/character_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when some lets are already in correct position" do
      let(:offense_code) do
        <<~RUBY
          describe Character do
            let(:bravo) { 2 }
            let(:alpha) { 1 }
            ^^^^^^^^^^^ Order consecutive `let` declarations alphabetically.
            let(:charlie) { 3 }
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          describe Character do
            let(:alpha) { 1 }
            let(:bravo) { 2 }
            let(:charlie) { 3 }
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/character_spec.rb")
      end

      it "autocorrects while leaving correctly positioned lets unchanged" do
        expect_offense(offense_code, "spec/models/character_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when ordering is case-insensitive" do
      it "does not register an offense for case-variant alphabetical order" do
        expect_no_offenses(<<~RUBY, "spec/models/character_spec.rb")
          describe Character do
            let(:Apple)  { create(:apple) }
            let(:banana) { create(:banana) }
          end
        RUBY
      end
    end
  end
end
