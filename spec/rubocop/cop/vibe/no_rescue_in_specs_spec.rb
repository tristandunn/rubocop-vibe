# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::NoRescueInSpecs, :config do
  describe "#on_resbody" do
    context "when file is not a spec file" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "app/models/user.rb")
          begin
            perform
          rescue StandardError
            nil
          end
        RUBY
      end
    end

    context "when there is no rescue" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          it "raises an error" do
            expect { perform }.to raise_error(StandardError)
          end
        RUBY
      end
    end

    context "when using a begin/rescue block" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          it "raises an error" do
            begin
              perform
            rescue StandardError
            ^^^^^^ Do not use `rescue` in specs. Use `expect { ... }.to raise_error` instead.
              nil
            end
          end
        RUBY
      end
    end

    context "when using a rescue in a block body" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          it "raises an error" do
            perform
          rescue
          ^^^^^^ Do not use `rescue` in specs. Use `expect { ... }.to raise_error` instead.
            nil
          end
        RUBY
      end
    end

    context "when using a modifier rescue" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          it "raises an error" do
            perform rescue nil
                    ^^^^^^ Do not use `rescue` in specs. Use `expect { ... }.to raise_error` instead.
          end
        RUBY
      end
    end

    context "when there are multiple rescue clauses" do
      it "registers an offense for each" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          begin
            perform
          rescue ArgumentError
          ^^^^^^ Do not use `rescue` in specs. Use `expect { ... }.to raise_error` instead.
            nil
          rescue StandardError
          ^^^^^^ Do not use `rescue` in specs. Use `expect { ... }.to raise_error` instead.
            nil
          end
        RUBY
      end
    end
  end
end
