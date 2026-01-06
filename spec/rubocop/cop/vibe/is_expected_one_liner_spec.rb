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
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
        it "matches attributes" do
          is_expected.to have_attributes(
            name: "Test",
            value: 42
          )
        end
      RUBY
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

  context "when is_expected is used in a let block" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
        RSpec.describe User do
          let(:result) { is_expected.to be_valid }
        end
      RUBY
    end
  end

  context "when is_expected is used outside any block" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
        is_expected.to be_valid
      RUBY
    end
  end

  context "when is_expected has multi-line matcher arguments" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
        it "sets access, cache, and content headers" do
          is_expected.to include(
            "access-control-allow-origin" => "*",
            "cache-control"               => "max-age=86400, public",
            "content-type"                => "application/javascript"
          )
        end
      RUBY
    end
  end

  context "when is_expected uses compound matchers" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
        it "returns the script content" do
          is_expected.to eq(
            Rails.application.assets.load_path.find("script.js").content
          ).and(include("fetch("))
        end
      RUBY
    end
  end

  context "when is_expected uses compound matcher on single line" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
        it "matches both conditions" do
          is_expected.to be_valid.and be_persisted
        end
      RUBY
    end
  end
end
