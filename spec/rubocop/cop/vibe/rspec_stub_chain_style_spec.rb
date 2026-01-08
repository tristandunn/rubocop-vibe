# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::RspecStubChainStyle, :config do
  let(:cop_config)      { {} }
  let(:other_cops)      do
    {
      "Layout/LineLength" => { "Max" => max_line_length }
    }
  end
  let(:max_line_length) { 80 }

  describe "#on_send" do
    context "when line exceeds max length with .with on same line as receive" do
      # Line is 84 chars: "    allow(SomeVeryLongServiceClassName).to receive(:method_name).with(argument_name)"
      let(:offense_code) do
        <<~RUBY
          RSpec.describe User do
            before do
              allow(SomeVeryLongServiceClassName).to receive(:method_name).with(argument_name)
                                                                           ^^^^ Put each chained stub method on its own line when line is too long.
            end
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          RSpec.describe User do
            before do
              allow(SomeVeryLongServiceClassName).to receive(:method_name)
                .with(argument_name)
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/user_spec.rb")
      end

      it "autocorrects by moving .with to a new line" do
        expect_offense(offense_code, "spec/models/user_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when line is within max length with .with on same line" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            before do
              allow(Foo).to receive(:bar).with(arg)
            end
          end
        RUBY
      end
    end

    context "when line exceeds max length with .with and .and_return" do
      # Line is 97 chars
      let(:offense_code) do
        <<~RUBY
          RSpec.describe User do
            before do
              allow(SomeVeryLongServiceClassName).to receive(:method_name).with(arg).and_return(result)
                                                                           ^^^^ Put each chained stub method on its own line when line is too long.
                                                                                     ^^^^^^^^^^ Put each chained stub method on its own line when line is too long.
            end
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          RSpec.describe User do
            before do
              allow(SomeVeryLongServiceClassName).to receive(:method_name)
                .with(arg)
                .and_return(result)
            end
          end
        RUBY
      end

      it "registers offenses for both methods" do
        expect_offense(offense_code, "spec/models/user_spec.rb")
      end

      it "autocorrects by moving both to new lines" do
        expect_offense(offense_code, "spec/models/user_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when .and_return is on the same line but no .with" do
      it "does not register an offense even if line is long" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            before do
              allow(SomeVeryLongServiceClassName).to receive(:method_name).and_return(some_result_value)
            end
          end
        RUBY
      end
    end

    context "when chain is already on separate lines" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            before do
              allow(SomeVeryLongServiceClassName).to receive(:method_name)
                .with(arg)
                .and_return(result)
            end
          end
        RUBY
      end
    end

    context "when using expect instead of allow with long line" do
      let(:offense_code) do
        <<~RUBY
          RSpec.describe User do
            before do
              expect(SomeVeryLongServiceClassName).to receive(:method_name).with(arg).and_return(result)
                                                                            ^^^^ Put each chained stub method on its own line when line is too long.
                                                                                      ^^^^^^^^^^ Put each chained stub method on its own line when line is too long.
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/user_spec.rb")
      end
    end

    context "when receive has no additional chain methods" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            before do
              allow(Foo).to receive(:bar)
            end
          end
        RUBY
      end
    end

    context "when using receive_message_chain with long line" do
      # Line is 92 chars
      let(:offense_code) do
        <<~RUBY
          RSpec.describe User do
            before do
              allow(SomeVeryLongServiceClassName).to receive_message_chain(:bar, :baz).with(argument)
                                                                                       ^^^^ Put each chained stub method on its own line when line is too long.
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/user_spec.rb")
      end
    end

    context "when using have_received with long line" do
      let(:offense_code) do
        <<~RUBY
          RSpec.describe User do
            it "verifies the call" do
              expect(SomeVeryLongServiceClassName).to have_received(:method_name).with(arg)
                                                                                  ^^^^ Put each chained stub method on its own line when line is too long.
            end
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          RSpec.describe User do
            it "verifies the call" do
              expect(SomeVeryLongServiceClassName).to have_received(:method_name)
                .with(arg)
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/user_spec.rb")
      end

      it "autocorrects" do
        expect_offense(offense_code, "spec/models/user_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when using .once after .with with long line" do
      # Line is 87 chars
      let(:offense_code) do
        <<~RUBY
          RSpec.describe User do
            before do
              allow(SomeVeryLongServiceClassName).to receive(:method_name).with(argument).once
                                                                           ^^^^ Put each chained stub method on its own line when line is too long.
                                                                                          ^^^^ Put each chained stub method on its own line when line is too long.
            end
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          RSpec.describe User do
            before do
              allow(SomeVeryLongServiceClassName).to receive(:method_name)
                .with(argument)
                .once
            end
          end
        RUBY
      end

      it "registers offenses" do
        expect_offense(offense_code, "spec/models/user_spec.rb")
      end

      it "autocorrects" do
        expect_offense(offense_code, "spec/models/user_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when in a non-spec file" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "app/models/user.rb")
          class User
            def setup_mock
              allow(SomeVeryLongServiceClassName).to receive(:method_name).with(arg).and_return(result)
            end
          end
        RUBY
      end
    end

    context "when .with has multi-line arguments on a long line" do
      # First line is 81 chars
      let(:offense_code) do
        <<~RUBY
          RSpec.describe User do
            before do
              allow(SomeVeryLongServiceClassNameHereXY).to receive(:method_name_here).with(
                                                                                      ^^^^ Put each chained stub method on its own line when line is too long.
                arg1,
                arg2
              ).and_return(result)
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/user_spec.rb")
      end
    end

    context "when using described_class with long line" do
      let(:offense_code) do
        <<~RUBY
          RSpec.describe User do
            before do
              allow(described_class::SomeNestedClassName).to receive(:new).with(arg).and_return(result)
                                                                           ^^^^ Put each chained stub method on its own line when line is too long.
                                                                                     ^^^^^^^^^^ Put each chained stub method on its own line when line is too long.
            end
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          RSpec.describe User do
            before do
              allow(described_class::SomeNestedClassName).to receive(:new)
                .with(arg)
                .and_return(result)
            end
          end
        RUBY
      end

      it "registers offenses" do
        expect_offense(offense_code, "spec/models/user_spec.rb")
      end

      it "autocorrects" do
        expect_offense(offense_code, "spec/models/user_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when only .with is present and already on its own line" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            before do
              allow(Foo).to receive(:bar)
                .with(arg)
            end
          end
        RUBY
      end
    end

    context "when to argument is not a receive chain" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            before do
              allow(SomeVeryLongServiceClassName).to have_attributes(bar: 1).with_something
            end
          end
        RUBY
      end
    end

    context "when receive has .with but nothing else" do
      it "does not register an offense when .with is on same line" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            before do
              expect(Foo).to receive(:bar)
            end
          end
        RUBY
      end
    end

    context "with a very high max line length" do
      let(:max_line_length) { 200 }

      it "does not register an offense for normally long lines" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            before do
              allow(SomeVeryLongServiceClassName).to receive(:method_name).with(arg).and_return(result)
            end
          end
        RUBY
      end
    end

    context "when Layout/LineLength Max is not configured" do
      let(:other_cops) { {} }

      it "defaults to 120 and does not register offense for line under 120" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            before do
              allow(SomeVeryLongServiceClassName).to receive(:method_name).with(arg).and_return(result)
            end
          end
        RUBY
      end
    end
  end
end
