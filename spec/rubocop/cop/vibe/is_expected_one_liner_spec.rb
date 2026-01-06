# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::IsExpectedOneLiner, :config do
  context "when is_expected is used with a description" do
    it "registers an offense" do
      expect_offense(<<~RUBY, "spec/models/user_spec.rb")
        it "returns true" do
        ^^^^^^^^^^^^^^^^^ Use one-liner `it { is_expected.to ... }` syntax when using `is_expected`.
          is_expected.to be(true)
        end
      RUBY

      expect_correction(<<~RUBY)
        it { is_expected.to be(true) }
      RUBY
    end
  end

  context "when is_expected is already a one-liner" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
        it { is_expected.to be(true) }
      RUBY
    end
  end

  context "when expect is used with a description" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
        it "returns the user" do
          expect(result).to eq(user)
        end
      RUBY
    end
  end

  context "when specify is used with is_expected" do
    it "registers an offense" do
      expect_offense(<<~RUBY, "spec/models/user_spec.rb")
        specify "it works" do
        ^^^^^^^^^^^^^^^^^^ Use one-liner `it { is_expected.to ... }` syntax when using `is_expected`.
          is_expected.to be_valid
        end
      RUBY

      expect_correction(<<~RUBY)
        it { is_expected.to be_valid }
      RUBY
    end
  end

  context "when is_expected has a multi-line expectation" do
    it "registers an offense but does not autocorrect" do
      expect_offense(<<~RUBY, "spec/models/user_spec.rb")
        it "matches attributes" do
        ^^^^^^^^^^^^^^^^^^^^^^^ Use one-liner `it { is_expected.to ... }` syntax when using `is_expected`.
          is_expected.to have_attributes(
            name: "Test",
            value: 42
          )
        end
      RUBY

      expect_no_corrections
    end
  end

  context "when is_expected is nested in a context" do
    it "registers an offense" do
      expect_offense(<<~RUBY, "spec/models/user_spec.rb")
        RSpec.describe User do
          context "when active" do
            it "is valid" do
            ^^^^^^^^^^^^^ Use one-liner `it { is_expected.to ... }` syntax when using `is_expected`.
              is_expected.to be_valid
            end
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        RSpec.describe User do
          context "when active" do
            it { is_expected.to be_valid }
          end
        end
      RUBY
    end
  end

  context "when is_expected.not_to is used with a description" do
    it "registers an offense" do
      expect_offense(<<~RUBY, "spec/models/user_spec.rb")
        it "is not empty" do
        ^^^^^^^^^^^^^^^^^ Use one-liner `it { is_expected.to ... }` syntax when using `is_expected`.
          is_expected.not_to be_empty
        end
      RUBY

      expect_correction(<<~RUBY)
        it { is_expected.not_to be_empty }
      RUBY
    end
  end

  context "when not in a spec file" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "app/models/user.rb")
        it "returns true" do
          is_expected.to be(true)
        end
      RUBY
    end
  end
end
