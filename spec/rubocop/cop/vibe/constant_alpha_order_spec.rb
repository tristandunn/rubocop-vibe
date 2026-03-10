# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::ConstantAlphaOrder, :config do
  describe "#on_class" do
    context "when consecutive constants are not alphabetically ordered" do
      let(:offense_code) do
        <<~RUBY
          class MyClass
            ZEBRA = 1
            ALPHA = 2
            ^^^^^^^^^ Order constants alphabetically by name.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class MyClass
            ALPHA = 2
            ZEBRA = 1
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by reordering constants" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when consecutive constants are already alphabetically ordered" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class MyClass
            ALPHA = 1
            ZEBRA = 2
          end
        RUBY
      end
    end

    context "when constants are separated by a blank line" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class MyClass
            ZEBRA = 1

            ALPHA = 2
          end
        RUBY
      end
    end

    context "when there is only one constant" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class MyClass
            ZEBRA = 1
          end
        RUBY
      end
    end

    context "when class body is empty" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class MyClass
          end
        RUBY
      end
    end

    context "when a non-constant statement appears between constants" do
      it "does not register an offense across groups" do
        expect_no_offenses(<<~RUBY)
          class MyClass
            ZEBRA = 1
            def foo; end
            ALPHA = 2
          end
        RUBY
      end
    end

    context "with multiple violations in the same group" do
      let(:offense_code) do
        <<~RUBY
          class MyClass
            DELTA = 1
            BETA  = 2
            ^^^^^^^^^ Order constants alphabetically by name.
            ALPHA = 3
            ^^^^^^^^^ Order constants alphabetically by name.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class MyClass
            ALPHA = 3
            BETA  = 2
            DELTA = 1
          end
        RUBY
      end

      it "registers an offense for each out-of-order constant" do
        expect_offense(offense_code)
      end

      it "autocorrects all declarations" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when some consecutive pairs are already in order within a group" do
      let(:offense_code) do
        <<~RUBY
          class MyClass
            ALPHA = 1
            DELTA = 2
            BETA  = 3
            ^^^^^^^^^ Order constants alphabetically by name.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class MyClass
            ALPHA = 1
            BETA  = 3
            DELTA = 2
          end
        RUBY
      end

      it "registers an offense only for the out-of-order pair" do
        expect_offense(offense_code)
      end

      it "autocorrects to full alphabetical order" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with two groups separated by a blank line" do
      let(:offense_code) do
        <<~RUBY
          class MyClass
            ZEBRA = 1
            ALPHA = 2
            ^^^^^^^^^ Order constants alphabetically by name.

            OMEGA = 3
            DELTA = 4
            ^^^^^^^^^ Order constants alphabetically by name.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class MyClass
            ALPHA = 2
            ZEBRA = 1

            DELTA = 4
            OMEGA = 3
          end
        RUBY
      end

      it "registers offenses for each unordered group" do
        expect_offense(offense_code)
      end

      it "autocorrects each group independently" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end
  end

  describe "#on_module" do
    context "when consecutive constants in a module are not alphabetically ordered" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          module MyModule
            ZEBRA = 1
            ALPHA = 2
            ^^^^^^^^^ Order constants alphabetically by name.
          end
        RUBY
      end
    end

    context "when module body is empty" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          module MyModule
          end
        RUBY
      end
    end
  end

  describe "#on_block" do
    context "when consecutive constants in a block are not alphabetically ordered" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          configure do
            ZEBRA = 1
            ALPHA = 2
            ^^^^^^^^^ Order constants alphabetically by name.
          end
        RUBY
      end
    end

    context "when block body is empty" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          configure do
          end
        RUBY
      end
    end
  end
end
