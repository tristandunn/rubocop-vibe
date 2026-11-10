# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::NoNestedExpect, :config do
  describe "#on_send" do
    context "when file is not a spec file" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "app/models/user.rb")
          expect { expect(user).to be_valid }.not_to raise_error
        RUBY
      end
    end

    context "when expect is not nested" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          it "is valid" do
            expect { perform }.to change { User.count }.by(1)
          end
        RUBY
      end
    end

    context "when expect is inside a non-expect block" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          it "is valid" do
            users.each { |user| expect(user).to be_valid }
          end
        RUBY
      end
    end

    context "when a method call named expect has a receiver" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          expect { helper.expect(user) }.to change { User.count }
        RUBY
      end
    end

    context "when expect is inside an expect block" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          it "is valid" do
            expect { expect(user).to be_valid }.not_to raise_error
                     ^^^^^^^^^^^^ Do not nest `expect` inside another `expect` block.
          end
        RUBY
      end
    end

    context "when an expect block is inside an expect block" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          it "is valid" do
            expect { expect { perform }.to raise_error }.not_to raise_error
                     ^^^^^^ Do not nest `expect` inside another `expect` block.
          end
        RUBY
      end
    end

    context "when expect is deeply nested in an expect block" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          it "is valid" do
            expect do
              users.each { |user| expect(user).to be_valid }
                                  ^^^^^^^^^^^^ Do not nest `expect` inside another `expect` block.
            end.not_to raise_error
          end
        RUBY
      end
    end
  end
end
