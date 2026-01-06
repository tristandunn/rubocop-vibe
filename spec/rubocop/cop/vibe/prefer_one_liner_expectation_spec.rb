# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::PreferOneLinerExpectation, :config do
  describe "#on_block" do
    context "when using multi-line syntax for simple expectation" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/controllers/users_controller_spec.rb")
          RSpec.describe UsersController do
            describe "#show" do
              it "responds with ok" do
              ^^^^^^^^^^^^^^^^^^^^^ Use one-liner `it { is_expected.to }` syntax for simple expectations.
                expect(subject).to respond_with(:ok)
              end
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          RSpec.describe UsersController do
            describe "#show" do
              it { expect(subject).to respond_with(:ok) }
            end
          end
        RUBY
      end
    end

    context "when using specify with simple expectation" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            specify "responds to name" do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ Use one-liner `it { is_expected.to }` syntax for simple expectations.
              expect(subject).to respond_to(:name)
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          RSpec.describe User do
            it { expect(subject).to respond_to(:name) }
          end
        RUBY
      end
    end

    context "when using block expectation with change" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            describe "#save" do
              it "creates a new record" do
                expect { subject.save }.to change(User, :count).by(1)
              end
            end
          end
        RUBY
      end
    end

    context "when using block expectation with raise_error" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/services/processor_spec.rb")
          RSpec.describe Processor do
            describe "#call" do
              it "raises an error" do
                expect { subject.call }.to raise_error(ArgumentError)
              end
            end
          end
        RUBY
      end
    end

    context "when test has setup code before expectation" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            describe "#process" do
              it "processes the user" do
                user.activate

                expect(user).to be_active
              end
            end
          end
        RUBY
      end
    end

    context "when test has multiple expectations" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/controllers/users_controller_spec.rb")
          RSpec.describe UsersController do
            describe "#show" do
              it "responds correctly" do
                expect(response).to have_http_status(:ok)
                expect(response).to render_template(:show)
              end
            end
          end
        RUBY
      end
    end

    context "when already using one-liner syntax" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/controllers/users_controller_spec.rb")
          RSpec.describe UsersController do
            describe "#show" do
              it { is_expected.to respond_with(:ok) }
            end
          end
        RUBY
      end
    end

    context "when using one-liner syntax with subject call" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            describe "#valid?" do
              it { expect(subject).to be_valid }
            end
          end
        RUBY
      end
    end

    context "when in a non-spec file" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "app/models/user.rb")
          class User
            def test
              it "responds with ok" do
                expect(subject).to respond_with(:ok)
              end
            end
          end
        RUBY
      end
    end

    context "when not in an it or specify block" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            let(:processed_user) do
              expect(user).to be_processed
            end
          end
        RUBY
      end
    end

    context "when using scenario block" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/features/users_spec.rb")
          RSpec.feature "Users" do
            scenario "viewing a user" do
              expect(page).to have_content("User")
            end
          end
        RUBY
      end
    end

    context "when expectation has multiple chained matchers" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            describe "#name" do
              it "has the correct name" do
              ^^^^^^^^^^^^^^^^^^^^^^^^^ Use one-liner `it { is_expected.to }` syntax for simple expectations.
                expect(subject.name).to eq("John").and be_a(String)
              end
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          RSpec.describe User do
            describe "#name" do
              it { expect(subject.name).to eq("John").and be_a(String) }
            end
          end
        RUBY
      end
    end

    context "when using expect with receiver other than subject" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            describe "#email" do
              it "has an email" do
              ^^^^^^^^^^^^^^^^^ Use one-liner `it { is_expected.to }` syntax for simple expectations.
                expect(user.email).to be_present
              end
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          RSpec.describe User do
            describe "#email" do
              it { expect(user.email).to be_present }
            end
          end
        RUBY
      end
    end

    context "when expectation uses assignment" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/services/creator_spec.rb")
          RSpec.describe Creator do
            describe "#call" do
              it "creates a user" do
                result = subject.call

                expect(result).to be_success
              end
            end
          end
        RUBY
      end
    end

    context "when expectation spans multiple lines" do
      it "registers offense but does not autocorrect" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            it "has valid attributes" do
            ^^^^^^^^^^^^^^^^^^^^^^^^^ Use one-liner `it { is_expected.to }` syntax for simple expectations.
              expect(subject).to have_attributes(
                name: "Test",
                email: "test@example.com"
              )
            end
          end
        RUBY

        expect_no_corrections
      end
    end

    context "when it block has no body" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            it "is pending" do
            end
          end
        RUBY
      end
    end

    context "when body is not a send type" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            it "returns a value" do
              42
            end
          end
        RUBY
      end
    end

    context "when body is a method call without expect" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            it "calls a method" do
              some_method.call
            end
          end
        RUBY
      end
    end
  end
end
