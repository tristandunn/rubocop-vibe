# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::BlankLineBeforeExpectation, :config do
  describe "#on_block" do
    context "when there is setup code before expectation" do
      let(:offense_code) do
        <<~RUBY
          RSpec.describe User do
            it "processes the record" do
              record.process
              expect(record).to be_processed
              ^^^^^^ Add a blank line before expectation when there is setup code above.
            end
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          RSpec.describe User do
            it "processes the record" do
              record.process

              expect(record).to be_processed
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/user_spec.rb")
      end

      it "autocorrects by adding a blank line" do
        expect_offense(offense_code, "spec/models/user_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when there are multiple setup lines before expectation" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            it "processes the record" do
              user = create(:user)
              record = create(:record, user: user)
              record.process
              expect(record).to be_processed
              ^^^^^^ Add a blank line before expectation when there is setup code above.
            end
          end
        RUBY
      end
    end

    context "when using specify instead of it" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            specify do
              record.process
              expect(record).to be_processed
              ^^^^^^ Add a blank line before expectation when there is setup code above.
            end
          end
        RUBY
      end
    end

    context "when using scenario instead of it" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/features/user_spec.rb")
          RSpec.describe User do
            scenario "processing a record" do
              record.process
              expect(record).to be_processed
              ^^^^^^ Add a blank line before expectation when there is setup code above.
            end
          end
        RUBY
      end
    end

    context "when there is already a blank line before expectation" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            it "processes the record" do
              record.process

              expect(record).to be_processed
            end
          end
        RUBY
      end
    end

    context "when expectation is the first statement" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            it "is valid" do
              expect(record).to be_valid
            end
          end
        RUBY
      end
    end

    context "when there are multiple consecutive expectations" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            it "has correct attributes" do
              expect(record.name).to eq("Test")
              expect(record.email).to eq("test@example.com")
              expect(record.active).to be(true)
            end
          end
        RUBY
      end
    end

    context "when there is setup then multiple expectations" do
      let(:multiple_expectations_offense) do
        <<~RUBY
          RSpec.describe User do
            it "has correct attributes" do
              record.process
              expect(record.name).to eq("Test")
              ^^^^^^ Add a blank line before expectation when there is setup code above.
              expect(record.email).to eq("test@example.com")
              expect(record.active).to be(true)
            end
          end
        RUBY
      end

      let(:multiple_expectations_correction) do
        <<~RUBY
          RSpec.describe User do
            it "has correct attributes" do
              record.process

              expect(record.name).to eq("Test")
              expect(record.email).to eq("test@example.com")
              expect(record.active).to be(true)
            end
          end
        RUBY
      end

      it "registers an offense only for the first expectation" do
        expect_offense(multiple_expectations_offense, "spec/models/user_spec.rb")
      end

      it "autocorrects by adding a blank line before first expectation" do
        expect_offense(multiple_expectations_offense, "spec/models/user_spec.rb")

        expect_correction(multiple_expectations_correction)
      end
    end

    context "when there are multiple groups of setup and expectations" do
      it "registers offenses for each expectation after setup" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            it "processes in stages" do
              record.start
              expect(record).to be_started
              ^^^^^^ Add a blank line before expectation when there is setup code above.
              record.process
              expect(record).to be_processed
              ^^^^^^ Add a blank line before expectation when there is setup code above.
            end
          end
        RUBY
      end
    end

    context "when using expect with block" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            it "creates a record" do
              record.prepare
              expect { record.save }.to change(Record, :count).by(1)
              ^^^^^^ Add a blank line before expectation when there is setup code above.
            end
          end
        RUBY
      end
    end

    context "when in a non-spec file" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "app/models/user.rb")
          class User
            def process
              record.process
              expect(record).to be_processed
            end
          end
        RUBY
      end
    end

    context "when not in an example block" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            let(:processed_record) do
              record.process
              expect(record).to be_processed
            end
          end
        RUBY
      end
    end

    context "when there is a comment between setup and expectation" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            it "processes the record" do
              record.process
              # Verify processing
              expect(record).to be_processed
            end
          end
        RUBY
      end
    end

    context "when example block has only one line" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            it { expect(record).to be_valid }
          end
        RUBY
      end
    end

    context "when previous statement is not a send node" do
      it "registers an offense for assignment before expect" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            it "creates a record" do
              result = do_something
              expect(result).to be_valid
              ^^^^^^ Add a blank line before expectation when there is setup code above.
            end
          end
        RUBY
      end
    end

    context "when statement is a literal value" do
      it "does not check non-send statements for expect" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            it "returns something" do
              42
            end
          end
        RUBY
      end
    end

    context "when expect is used without matcher chain" do
      it "registers an offense for bare expect call after setup" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            it "gets expectation target" do
              record.process
              expect(record)
              ^^^^^^ Add a blank line before expectation when there is setup code above.
            end
          end
        RUBY
      end
    end
  end
end
