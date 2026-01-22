# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::RspecBeforeBlockStyle, :config do
  describe "#on_block" do
    context "when using braces for before block" do
      let(:offense_code) do
        <<~RUBY
          RSpec.describe User do
            before { setup_data }
                   ^ Use `do...end` block syntax instead of braces for `before` blocks.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          RSpec.describe User do
            before do
              setup_data
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/user_spec.rb")
      end

      it "autocorrects to do...end syntax" do
        expect_offense(offense_code, "spec/models/user_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when using braces for before(:each) block" do
      let(:offense_code) do
        <<~RUBY
          RSpec.describe User do
            before(:each) { setup_data }
                          ^ Use `do...end` block syntax instead of braces for `before` blocks.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          RSpec.describe User do
            before(:each) do
              setup_data
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/user_spec.rb")
      end

      it "autocorrects to do...end syntax" do
        expect_offense(offense_code, "spec/models/user_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when using braces for before(:all) block" do
      let(:offense_code) do
        <<~RUBY
          RSpec.describe User do
            before(:all) { setup_data }
                         ^ Use `do...end` block syntax instead of braces for `before` blocks.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          RSpec.describe User do
            before(:all) do
              setup_data
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/user_spec.rb")
      end

      it "autocorrects to do...end syntax" do
        expect_offense(offense_code, "spec/models/user_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when using braces for after block" do
      let(:offense_code) do
        <<~RUBY
          RSpec.describe User do
            after { cleanup_data }
                  ^ Use `do...end` block syntax instead of braces for `after` blocks.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          RSpec.describe User do
            after do
              cleanup_data
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/user_spec.rb")
      end

      it "autocorrects to do...end syntax" do
        expect_offense(offense_code, "spec/models/user_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when using braces for around block" do
      let(:offense_code) do
        <<~RUBY
          RSpec.describe User do
            around { |example| example.run }
                   ^ Use `do...end` block syntax instead of braces for `around` blocks.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          RSpec.describe User do
            around do |example|
              example.run
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/user_spec.rb")
      end

      it "autocorrects to do...end syntax" do
        expect_offense(offense_code, "spec/models/user_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when block body has multiple statements" do
      let(:offense_code) do
        <<~RUBY
          RSpec.describe User do
            before { setup_data; process_data }
                   ^ Use `do...end` block syntax instead of braces for `before` blocks.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          RSpec.describe User do
            before do
              setup_data; process_data
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/user_spec.rb")
      end

      it "autocorrects to do...end syntax" do
        expect_offense(offense_code, "spec/models/user_spec.rb")

        expect_correction(corrected_code)
      end
    end

    context "when already using do...end syntax" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            before do
              setup_data
            end
          end
        RUBY
      end
    end

    context "when already using do...end syntax with argument" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            before(:each) do
              setup_data
            end
          end
        RUBY
      end
    end

    context "when in a non-spec file" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "app/models/user.rb")
          class User
            def before(&block)
              block.call
            end

            def test
              before { setup_data }
            end
          end
        RUBY
      end
    end

    context "when before is called on a receiver" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            it "does something" do
              object.before { setup_data }
            end
          end
        RUBY
      end
    end

    context "when block has no body" do
      let(:offense_code) do
        <<~RUBY
          RSpec.describe User do
            before { }
                   ^ Use `do...end` block syntax instead of braces for `before` blocks.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          RSpec.describe User do
            before do
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/models/user_spec.rb")
      end

      it "autocorrects to do...end syntax" do
        expect_offense(offense_code, "spec/models/user_spec.rb")

        expect_correction(corrected_code)
      end
    end
  end
end
