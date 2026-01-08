# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::NoRubocopDisable, :config do
  let(:cop_config)   { { "AllowedCops" => allowed_cops } }
  let(:allowed_cops) { [] }

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
      it "registers an offense for the specific cop" do
        expect_offense(<<~RUBY)
          def method
            "string" # rubocop:disable Style/StringLiterals
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not disable `Style/StringLiterals`. Fix the issue or configure globally in `.rubocop.yml`.
          end
        RUBY
      end
    end

    context "when there is a block rubocop:disable comment" do
      it "registers an offense for the specific cop" do
        expect_offense(<<~RUBY)
          # rubocop:disable Style/StringLiterals
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not disable `Style/StringLiterals`. Fix the issue or configure globally in `.rubocop.yml`.
          def method
            "string"
          end
        RUBY
      end
    end

    context "when there are multiple cops disabled in one comment" do
      it "registers one offense listing all cops" do
        expect_offense(<<~RUBY)
          # rubocop:disable Style/StringLiterals, Metrics/MethodLength
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not disable `Style/StringLiterals, Metrics/MethodLength`. Fix the issue or configure globally in `.rubocop.yml`.
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
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not disable `Style/StringLiterals`. Fix the issue or configure globally in `.rubocop.yml`.
          def method
            "string" # rubocop:disable Style/FrozenStringLiteralComment
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not disable `Style/FrozenStringLiteralComment`. Fix the issue or configure globally in `.rubocop.yml`.
          end
        RUBY
      end
    end

    context "when rubocop:disable has no cop specified" do
      # Note: "# rubocop:disable all" cannot be detected because it disables our cop.
      # We can only detect "# rubocop:disable" without any argument.
      it "registers an offense with generic message" do
        expect_offense(<<~RUBY)
          # rubocop:disable
          ^^^^^^^^^^^^^^^^^ Do not use `# rubocop:disable`. Fix the issue or configure globally in `.rubocop.yml`.
          def method
            "string"
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
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not disable `Style/StringLiterals`. Fix the issue or configure globally in `.rubocop.yml`.
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
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not disable `Style/StringLiterals`. Fix the issue or configure globally in `.rubocop.yml`.
          def method
            "string"
          end
        RUBY
      end
    end
  end

  describe "AllowedCops configuration" do
    context "when the disabled cop is in AllowedCops" do
      let(:allowed_cops) { ["Rails/RakeEnvironment"] }

      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          # rubocop:disable Rails/RakeEnvironment
          task :my_task do
            puts "hello"
          end
        RUBY
      end
    end

    context "when the disabled cop is not in AllowedCops" do
      let(:allowed_cops) { ["Rails/RakeEnvironment"] }

      it "registers an offense" do
        expect_offense(<<~RUBY)
          # rubocop:disable Style/StringLiterals
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not disable `Style/StringLiterals`. Fix the issue or configure globally in `.rubocop.yml`.
          def method
            "string"
          end
        RUBY
      end
    end

    context "when multiple cops are disabled and some are allowed" do
      let(:allowed_cops) { ["Rails/RakeEnvironment"] }

      it "only registers offense for disallowed cop" do
        expect_offense(<<~RUBY)
          # rubocop:disable Rails/RakeEnvironment, Style/StringLiterals
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not disable `Style/StringLiterals`. Fix the issue or configure globally in `.rubocop.yml`.
          task :my_task do
            puts "hello"
          end
        RUBY
      end
    end

    context "when multiple cops are disabled and all are allowed" do
      let(:allowed_cops) { ["Rails/RakeEnvironment", "Style/StringLiterals"] }

      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          # rubocop:disable Rails/RakeEnvironment, Style/StringLiterals
          task :my_task do
            puts "hello"
          end
        RUBY
      end
    end

    context "when multiple cops are disabled and none are allowed" do
      let(:allowed_cops) { [] }

      it "registers one offense listing all cops" do
        expect_offense(<<~RUBY)
          # rubocop:disable Rails/RakeEnvironment, Style/StringLiterals
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not disable `Rails/RakeEnvironment, Style/StringLiterals`. Fix the issue or configure globally in `.rubocop.yml`.
          task :my_task do
            puts "hello"
          end
        RUBY
      end
    end

    context "when no cop is specified even with AllowedCops configured" do
      let(:allowed_cops) { ["Rails/RakeEnvironment"] }

      # Note: "# rubocop:disable all" cannot be detected because it disables our cop.
      it "still registers an offense for empty disable directive" do
        expect_offense(<<~RUBY)
          # rubocop:disable
          ^^^^^^^^^^^^^^^^^ Do not use `# rubocop:disable`. Fix the issue or configure globally in `.rubocop.yml`.
          task :my_task do
            puts "hello"
          end
        RUBY
      end
    end
  end
end
