# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::ExplicitReturnConditional, :config do
  describe "ternary operators" do
    context "when ternary is the return value of a method" do
      let(:offense_code) do
        <<~RUBY
          def allow_origin
            origin = request.headers["Origin"]

            origin_allowed?(origin) ? origin : "*"
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use explicit `if`/`else`/`end` block instead of ternary operator for return value.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def allow_origin
            origin = request.headers["Origin"]

            if origin_allowed?(origin)
              origin
            else
              "*"
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects to explicit if/else/end block" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when ternary is the only statement in a method" do
      let(:offense_code) do
        <<~RUBY
          def status
            active? ? "active" : "inactive"
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use explicit `if`/`else`/`end` block instead of ternary operator for return value.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def status
            if active?
              "active"
            else
              "inactive"
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects to explicit if/else/end block" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when ternary is used in assignment (not return value)" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def example
            result = condition ? "yes" : "no"
            process(result)
          end
        RUBY
      end
    end

    context "when ternary is in the middle of a method" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def example
            value = condition ? "yes" : "no"
            puts value
            "done"
          end
        RUBY
      end
    end

    context "when method body is explicit if/else/end" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def allow_origin
            if origin_allowed?(origin)
              origin
            else
              "*"
            end
          end
        RUBY
      end
    end

    context "when return value is explicit if/else/end after other statements" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def allow_origin
            origin = request.headers["Origin"]

            if origin_allowed?(origin)
              origin
            else
              "*"
            end
          end
        RUBY
      end
    end

    context "when ternary has complex condition" do
      let(:offense_code) do
        <<~RUBY
          def result
            (a && b) || c ? "yes" : "no"
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use explicit `if`/`else`/`end` block instead of ternary operator for return value.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def result
            if (a && b) || c
              "yes"
            else
              "no"
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects preserving the condition" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when ternary is in a singleton method" do
      let(:offense_code) do
        <<~RUBY
          def self.status
            active? ? "active" : "inactive"
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use explicit `if`/`else`/`end` block instead of ternary operator for return value.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def self.status
            if active?
              "active"
            else
              "inactive"
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects to explicit if/else/end block" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end
  end

  describe "trailing conditionals" do
    context "when trailing if is the return value of a method" do
      let(:offense_code) do
        <<~RUBY
          def vary
            "Origin" if website.present?
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use explicit `if`/`end` block instead of trailing conditional for return value.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def vary
            if website.present?
              "Origin"
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects to explicit if/end block" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when trailing unless is the return value of a method" do
      let(:offense_code) do
        <<~RUBY
          def message
            "Error" unless valid?
            ^^^^^^^^^^^^^^^^^^^^^ Use explicit `if`/`end` block instead of trailing conditional for return value.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def message
            if !valid?
              "Error"
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects to explicit if/end block with negated condition" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when trailing conditional is in the middle of a method" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def example
            log("starting") if verbose?
            process
            "done"
          end
        RUBY
      end
    end

    context "when method body is explicit if/end" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def vary
            if website.present?
              "Origin"
            end
          end
        RUBY
      end
    end

    context "when trailing conditional is used for side effects in the middle" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def process
            validate! if strict_mode?
            compute_result
          end
        RUBY
      end
    end

    context "when trailing if is in a singleton method" do
      let(:offense_code) do
        <<~RUBY
          def self.vary
            "Origin" if website.present?
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use explicit `if`/`end` block instead of trailing conditional for return value.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def self.vary
            if website.present?
              "Origin"
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects to explicit if/end block" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when trailing if follows other statements" do
      let(:offense_code) do
        <<~RUBY
          def header_value
            value = compute_value
            process(value)

            "special" if special_case?
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ Use explicit `if`/`end` block instead of trailing conditional for return value.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def header_value
            value = compute_value
            process(value)

            if special_case?
              "special"
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects to explicit if/end block" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when unless condition is already negated" do
      let(:offense_code) do
        <<~RUBY
          def message
            "Error" unless !invalid?
            ^^^^^^^^^^^^^^^^^^^^^^^^ Use explicit `if`/`end` block instead of trailing conditional for return value.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def message
            if invalid?
              "Error"
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by removing double negation" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end
  end

  describe "edge cases" do
    context "when method has no body" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def empty_method
          end
        RUBY
      end
    end

    context "when method body is a simple value" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def answer
            42
          end
        RUBY
      end
    end

    context "when nested ternary in assignment" do
      it "does not register an offense for non-return ternary" do
        expect_no_offenses(<<~RUBY)
          def example
            x = a ? (b ? 1 : 2) : 3
            x + 1
          end
        RUBY
      end
    end

    context "when ternary has method calls as values" do
      let(:offense_code) do
        <<~RUBY
          def result
            success? ? render_success : render_failure
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use explicit `if`/`else`/`end` block instead of ternary operator for return value.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def result
            if success?
              render_success
            else
              render_failure
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects preserving method calls" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when trailing conditional has method call as body" do
      let(:offense_code) do
        <<~RUBY
          def result
            render_special if special?
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ Use explicit `if`/`end` block instead of trailing conditional for return value.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def result
            if special?
              render_special
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects preserving method call" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end
  end
end
