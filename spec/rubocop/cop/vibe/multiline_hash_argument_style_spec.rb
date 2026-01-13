# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::MultilineHashArgumentStyle, :config do
  describe "#on_send" do
    context "when multiple hash pairs on same line in multiline call" do
      let(:offense_code) do
        <<~RUBY
          SomeService.call(
            website_id: website.id, data: data
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Hash arguments in multiline calls should be one per line and alphabetically ordered.
          )
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          SomeService.call(
            data: data,
            website_id: website.id
          )
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by splitting and sorting" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when hash pairs on separate lines but not alphabetically ordered" do
      let(:offense_code) do
        <<~RUBY
          SomeService.call(
            zebra: 1,
            ^^^^^^^^^ Hash arguments in multiline calls should be one per line and alphabetically ordered.
            alpha: 2
          )
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          SomeService.call(
            alpha: 2,
            zebra: 1
          )
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by reordering alphabetically" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when hash pairs are already correctly formatted" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          SomeService.call(
            alpha: 1,
            beta: 2,
            gamma: 3
          )
        RUBY
      end
    end

    context "when there is only one hash pair" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          SomeService.call(
            data: data
          )
        RUBY
      end
    end

    context "when closing paren is not on its own line" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          SomeService.call(zebra: 1, alpha: 2)
        RUBY
      end
    end

    context "when method call is not parenthesized" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          some_method zebra: 1, alpha: 2
        RUBY
      end
    end

    context "with mixed positional and keyword arguments" do
      let(:offense_code) do
        <<~RUBY
          SomeService.call(
            "positional",
            zebra: 1, alpha: 2
            ^^^^^^^^^^^^^^^^^^ Hash arguments in multiline calls should be one per line and alphabetically ordered.
          )
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          SomeService.call(
            "positional",
            alpha: 2,
            zebra: 1
          )
        RUBY
      end

      it "registers an offense for hash arguments" do
        expect_offense(offense_code)
      end

      it "autocorrects the hash arguments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with string keys" do
      let(:offense_code) do
        <<~RUBY
          SomeService.call(
            "zebra" => 1, "alpha" => 2
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ Hash arguments in multiline calls should be one per line and alphabetically ordered.
          )
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          SomeService.call(
            "alpha" => 2,
            "zebra" => 1
          )
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects alphabetically" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with hash rocket syntax" do
      let(:offense_code) do
        <<~RUBY
          SomeService.call(
            :zebra => 1, :alpha => 2
            ^^^^^^^^^^^^^^^^^^^^^^^^ Hash arguments in multiline calls should be one per line and alphabetically ordered.
          )
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          SomeService.call(
            :alpha => 2,
            :zebra => 1
          )
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects alphabetically" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with three or more hash pairs unordered" do
      let(:offense_code) do
        <<~RUBY
          SomeService.call(
            gamma: 3,
            ^^^^^^^^^ Hash arguments in multiline calls should be one per line and alphabetically ordered.
            alpha: 1,
            beta: 2
          )
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          SomeService.call(
            alpha: 1,
            beta: 2,
            gamma: 3
          )
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects all pairs" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when method call has no arguments" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          SomeService.call(
          )
        RUBY
      end
    end

    context "when method call has only positional arguments" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          SomeService.call(
            "arg1",
            "arg2"
          )
        RUBY
      end
    end

    context "with variable keys in hash" do
      let(:offense_code) do
        <<~RUBY
          SomeService.call(
            zebra_key => 1, alpha_key => 2
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Hash arguments in multiline calls should be one per line and alphabetically ordered.
          )
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          SomeService.call(
            alpha_key => 2,
            zebra_key => 1
          )
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects using source as key name" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with safe navigation operator" do
      let(:offense_code) do
        <<~RUBY
          service&.call(
            zebra: 1, alpha: 2
            ^^^^^^^^^^^^^^^^^^ Hash arguments in multiline calls should be one per line and alphabetically ordered.
          )
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          service&.call(
            alpha: 2,
            zebra: 1
          )
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with case-sensitive alphabetical sorting" do
      let(:offense_code) do
        <<~RUBY
          SomeService.call(
            Zebra: 1, alpha: 2
            ^^^^^^^^^^^^^^^^^^ Hash arguments in multiline calls should be one per line and alphabetically ordered.
          )
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          SomeService.call(
            Zebra: 1,
            alpha: 2
          )
        RUBY
      end

      it "registers an offense for inline but sorts by string value" do
        expect_offense(offense_code)
      end

      it "autocorrects using string comparison" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end
  end
end
