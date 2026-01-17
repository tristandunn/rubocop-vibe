# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::ConsecutiveIndexedAssignmentAlignment, :config do
  describe "#on_def" do
    context "when consecutive indexed assignments are not aligned" do
      let(:offense_code) do
        <<~RUBY
          def setup
            response.headers["Cache-Control"] = "public, max-age=3600"
            response.headers["Content-Type"] = "application/javascript"
                            ^^^^^^^^^^^^^^^^ Align consecutive indexed assignments at the = operator.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def setup
            response.headers["Cache-Control"] = "public, max-age=3600"
            response.headers["Content-Type"]  = "application/javascript"
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning assignments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when consecutive indexed assignments are already aligned" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def setup
            response.headers["Cache-Control"] = "public, max-age=3600"
            response.headers["Content-Type"]  = "application/javascript"
          end
        RUBY
      end
    end

    context "when indexed assignments are separated by blank lines" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def setup
            response.headers["Cache-Control"] = "public, max-age=3600"
            response.headers["Content-Type"]  = "application/javascript"

            hash["key"] = "value"
          end
        RUBY
      end
    end

    context "when there is only one indexed assignment" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def setup
            response.headers["Content-Type"] = "text/html"
          end
        RUBY
      end
    end

    context "when indexed assignments are in separate groups" do
      let(:offense_code) do
        <<~RUBY
          def setup
            hash["a"] = 1
                ^^^^^ Align consecutive indexed assignments at the = operator.
            hash["bb"] = 2

            other["x"] = 10
                 ^^^^^ Align consecutive indexed assignments at the = operator.
            other["yy"] = 20
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def setup
            hash["a"]  = 1
            hash["bb"] = 2

            other["x"]  = 10
            other["yy"] = 20
          end
        RUBY
      end

      it "registers offenses for each misaligned group" do
        expect_offense(offense_code)
      end

      it "autocorrects each group independently" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when non-indexed-assignment statements break up assignments" do
      it "does not register an offense for separated assignments" do
        expect_no_offenses(<<~RUBY)
          def setup
            hash["a"] = 1
            process(hash)
            hash["bb"] = 2
          end
        RUBY
      end
    end

    context "when there are two consecutive indexed assignments" do
      let(:offense_code) do
        <<~RUBY
          def setup
            h["a"] = 1
             ^^^^^ Align consecutive indexed assignments at the = operator.
            h["bb"] = 2
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def setup
            h["a"]  = 1
            h["bb"] = 2
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning assignments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end
  end

  describe "#on_defs" do
    context "when consecutive indexed assignments in a singleton method are not aligned" do
      let(:offense_code) do
        <<~RUBY
          def self.setup
            hash["a"] = 1
                ^^^^^ Align consecutive indexed assignments at the = operator.
            hash["bb"] = 2
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def self.setup
            hash["a"]  = 1
            hash["bb"] = 2
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning assignments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end
  end

  describe "#on_block" do
    context "when consecutive indexed assignments in a block are not aligned" do
      let(:offense_code) do
        <<~RUBY
          RSpec.describe User do
            it "sets headers" do
              response.headers["Cache-Control"] = "no-cache"
              response.headers["Content-Type"] = "text/html"
                              ^^^^^^^^^^^^^^^^ Align consecutive indexed assignments at the = operator.
            end
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          RSpec.describe User do
            it "sets headers" do
              response.headers["Cache-Control"] = "no-cache"
              response.headers["Content-Type"]  = "text/html"
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning assignments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when block has no body" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          items.each { |item| }
        RUBY
      end
    end

    context "when using numbered block parameters" do
      let(:offense_code) do
        <<~RUBY
          items.map do
            hash["a"] = _1
                ^^^^^ Align consecutive indexed assignments at the = operator.
            hash["bb"] = _2
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          items.map do
            hash["a"]  = _1
            hash["bb"] = _2
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning assignments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end
  end

  describe "edge cases" do
    context "when indexed assignments have multi-line RHS" do
      let(:offense_code) do
        <<~RUBY
          def setup
            hash["a"] = build(
                ^^^^^ Align consecutive indexed assignments at the = operator.
              :item,
              name: "Test"
            )
            hash["bb"] = value
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def setup
            hash["a"]  = build(
              :item,
              name: "Test"
            )
            hash["bb"] = value
          end
        RUBY
      end

      it "registers an offense on the shorter key" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning assignments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when multi-line RHS creates a gap" do
      it "treats all consecutive indexed assignments as same group despite multi-line RHS" do
        expect_offense(<<~RUBY)
          def setup
            h["a"] = foo
             ^^^^^ Align consecutive indexed assignments at the = operator.
            h["bb"] = bar(
             ^^^^^^ Align consecutive indexed assignments at the = operator.
              baz
            )
            h["ccc"] = qux
          end
        RUBY
      end
    end

    context "with symbol keys" do
      let(:offense_code) do
        <<~RUBY
          def setup
            hash[:a] = 1
                ^^^^ Align consecutive indexed assignments at the = operator.
            hash[:bb] = 2
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def setup
            hash[:a]  = 1
            hash[:bb] = 2
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning assignments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with integer keys" do
      let(:offense_code) do
        <<~RUBY
          def setup
            array[1] = "a"
                 ^^^ Align consecutive indexed assignments at the = operator.
            array[10] = "b"
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def setup
            array[1]  = "a"
            array[10] = "b"
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning assignments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with variable keys" do
      let(:offense_code) do
        <<~RUBY
          def setup
            hash[a] = 1
                ^^^ Align consecutive indexed assignments at the = operator.
            hash[long_key] = 2
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def setup
            hash[a]        = 1
            hash[long_key] = 2
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning assignments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with different receivers" do
      let(:offense_code) do
        <<~RUBY
          def setup
            hash["key"] = 1
                ^^^^^^^ Align consecutive indexed assignments at the = operator.
            other_hash["key"] = 2
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def setup
            hash["key"]       = 1
            other_hash["key"] = 2
          end
        RUBY
      end

      it "still aligns consecutive indexed assignments" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning assignments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with mixed regular and indexed assignments" do
      it "indexed assignment breaks local variable alignment group" do
        expect_no_offenses(<<~RUBY)
          def setup
            user = create(:user)
            hash["key"] = "value"
            character = create(:character)
          end
        RUBY
      end
    end

    context "when autocorrecting ensures at least one space" do
      let(:offense_code) do
        <<~RUBY
          def setup
            hash["very_long_key_name"] = 1
            hash["x"] = 2
                ^^^^^ Align consecutive indexed assignments at the = operator.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def setup
            hash["very_long_key_name"] = 1
            hash["x"]                  = 2
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects with proper spacing" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when there is only one indexed assignment" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def process
            result["key"] = compute_value
          end
        RUBY
      end
    end

    context "when method has no body" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def empty_method
          end
        RUBY
      end
    end

    context "with nested receivers" do
      let(:offense_code) do
        <<~RUBY
          def setup
            obj.nested.hash["a"] = 1
                           ^^^^^ Align consecutive indexed assignments at the = operator.
            obj.nested.hash["bb"] = 2
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def setup
            obj.nested.hash["a"]  = 1
            obj.nested.hash["bb"] = 2
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning assignments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with three consecutive indexed assignments" do
      let(:offense_code) do
        <<~RUBY
          def setup
            h["a"] = 1
             ^^^^^ Align consecutive indexed assignments at the = operator.
            h["bb"] = 2
             ^^^^^^ Align consecutive indexed assignments at the = operator.
            h["ccc"] = 3
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def setup
            h["a"]   = 1
            h["bb"]  = 2
            h["ccc"] = 3
          end
        RUBY
      end

      it "registers offenses for misaligned assignments" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning all assignments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end
  end
end
