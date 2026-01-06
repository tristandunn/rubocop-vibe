# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::NoSkippedTests, :config do
  describe "#on_send" do
    context "when file is not a spec file" do
      it "does not register an offense for skip" do
        expect_no_offenses(<<~RUBY, "app/models/user.rb")
          skip "reason"
        RUBY
      end
    end

    context "when there are no skipped tests" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          describe User do
            it "is valid" do
              expect(user).to be_valid
            end
          end
        RUBY
      end
    end

    context "when there is a skip call" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          it "does something" do
            skip "not implemented yet"
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not skip tests. Implement or delete the test.
          end
        RUBY
      end
    end

    context "when there is a skip call without message" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          it "does something" do
            skip
            ^^^^ Do not skip tests. Implement or delete the test.
          end
        RUBY
      end
    end

    context "when there is a pending call" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          it "does something" do
            pending "waiting on feature"
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not mark tests as pending. Implement or delete the test.
          end
        RUBY
      end
    end

    context "when there is a pending call without message" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          it "does something" do
            pending
            ^^^^^^^ Do not mark tests as pending. Implement or delete the test.
          end
        RUBY
      end
    end

    context "when using xit" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          xit "does something" do
          ^^^^^^^^^^^^^^^^^^^^ Do not use `xit`. Implement or delete the test.
            expect(true).to be true
          end
        RUBY
      end
    end

    context "when using xspecify" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          xspecify "does something" do
          ^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `xspecify`. Implement or delete the test.
            expect(true).to be true
          end
        RUBY
      end
    end

    context "when using xexample" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          xexample "does something" do
          ^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `xexample`. Implement or delete the test.
            expect(true).to be true
          end
        RUBY
      end
    end

    context "when using xdescribe" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          xdescribe "MyClass" do
          ^^^^^^^^^^^^^^^^^^^ Do not use `xdescribe`. Implement or delete the test.
            it "works" do
            end
          end
        RUBY
      end
    end

    context "when using xcontext" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          xcontext "when something" do
          ^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `xcontext`. Implement or delete the test.
            it "works" do
            end
          end
        RUBY
      end
    end

    context "when using xfeature" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          xfeature "login" do
          ^^^^^^^^^^^^^^^^ Do not use `xfeature`. Implement or delete the test.
            scenario "works" do
            end
          end
        RUBY
      end
    end

    context "when using xscenario" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          xscenario "does something" do
          ^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `xscenario`. Implement or delete the test.
            expect(true).to be true
          end
        RUBY
      end
    end

    context "when there are multiple skipped tests" do
      it "registers multiple offenses" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          describe User do
            xit "does something" do
            ^^^^^^^^^^^^^^^^^^^^ Do not use `xit`. Implement or delete the test.
            end

            it "does another thing" do
              skip
              ^^^^ Do not skip tests. Implement or delete the test.
            end

            it "does yet another thing" do
              pending
              ^^^^^^^ Do not mark tests as pending. Implement or delete the test.
            end
          end
        RUBY
      end
    end
  end
end
