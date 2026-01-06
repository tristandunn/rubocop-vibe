# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::NoRubocopDisable, :config do
  describe "#on_new_investigation" do
    context "when there are no rubocop:disable comments" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def method
            "string"
          end
        RUBY
      end
    end

    context "when there is an inline rubocop:disable comment" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def method
            "string" # rubocop:disable Style/StringLiterals
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `# rubocop:disable`. Fix the issue or configure globally in `.rubocop.yml`.
          end
        RUBY
      end
    end

    context "when there is a block rubocop:disable comment" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          # rubocop:disable Style/StringLiterals
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `# rubocop:disable`. Fix the issue or configure globally in `.rubocop.yml`.
          def method
            "string"
          end
        RUBY
      end
    end

    context "when there are multiple rubocop:disable comments" do
      it "registers multiple offenses" do
        expect_offense(<<~RUBY)
          # rubocop:disable Style/StringLiterals
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `# rubocop:disable`. Fix the issue or configure globally in `.rubocop.yml`.
          def method
            "string" # rubocop:disable Style/FrozenStringLiteralComment
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `# rubocop:disable`. Fix the issue or configure globally in `.rubocop.yml`.
          end
        RUBY
      end
    end

    context "when there is a rubocop:enable comment without disable" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def method
            "string"
          end
          # rubocop:enable Style/StringLiterals
        RUBY
      end
    end

    context "when there is a rubocop:todo comment" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          # rubocop:todo Style/StringLiterals
          def method
            "string"
          end
        RUBY
      end
    end

    context "when the comment mentions rubocop:disable in prose" do
      it "does not register an offense for non-directive text" do
        expect_no_offenses(<<~RUBY)
          # This method uses rubocop:disable which is bad
          def method
            "string"
          end
        RUBY
      end
    end

    context "when rubocop:disable has unusual spacing" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          #rubocop:disable Style/StringLiterals
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `# rubocop:disable`. Fix the issue or configure globally in `.rubocop.yml`.
          def method
            "string"
          end
        RUBY
      end
    end

    context "when rubocop:disable is mixed case" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          # RuboCop:Disable Style/StringLiterals
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `# rubocop:disable`. Fix the issue or configure globally in `.rubocop.yml`.
          def method
            "string"
          end
        RUBY
      end
    end
  end
end
