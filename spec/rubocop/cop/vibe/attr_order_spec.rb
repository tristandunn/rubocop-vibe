# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::AttrOrder, :config do
  describe "#on_send" do
    context "when attr_reader arguments are not alphabetically ordered" do
      let(:offense_code) do
        <<~RUBY
          class User
            attr_reader :id, :content, :timestamp, :raw
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Order `attr_reader` arguments alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class User
            attr_reader :content, :id, :raw, :timestamp
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by reordering arguments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when attr_reader arguments are alphabetically ordered" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User
            attr_reader :content, :id, :raw, :timestamp
          end
        RUBY
      end
    end

    context "when attr_reader has only one argument" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User
            attr_reader :id
          end
        RUBY
      end
    end

    context "when attr_writer arguments are not alphabetically ordered" do
      let(:offense_code) do
        <<~RUBY
          class User
            attr_writer :zebra, :apple
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ Order `attr_writer` arguments alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class User
            attr_writer :apple, :zebra
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by reordering arguments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when attr_writer arguments are alphabetically ordered" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User
            attr_writer :apple, :zebra
          end
        RUBY
      end
    end

    context "when attr_accessor arguments are not alphabetically ordered" do
      let(:offense_code) do
        <<~RUBY
          class User
            attr_accessor :name, :email, :age
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Order `attr_accessor` arguments alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class User
            attr_accessor :age, :email, :name
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by reordering arguments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when attr_accessor arguments are alphabetically ordered" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User
            attr_accessor :age, :email, :name
          end
        RUBY
      end
    end

    context "when there are two unordered arguments" do
      let(:offense_code) do
        <<~RUBY
          class User
            attr_reader :bb, :aa
            ^^^^^^^^^^^^^^^^^^^^ Order `attr_reader` arguments alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class User
            attr_reader :aa, :bb
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by reordering arguments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with case-sensitive ordering" do
      it "does not register an offense for case-variant alphabetical order" do
        expect_no_offenses(<<~RUBY)
          class User
            attr_reader :Apple, :banana
          end
        RUBY
      end
    end

    context "when attr_* has a receiver" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User
            self.attr_reader :zebra, :apple
          end
        RUBY
      end
    end

    context "when attr_* has no arguments" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User
            attr_reader
          end
        RUBY
      end
    end

    context "with multiple attr_* declarations" do
      let(:offense_code) do
        <<~RUBY
          class User
            attr_reader :zebra, :apple
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ Order `attr_reader` arguments alphabetically.
            attr_writer :delta, :bravo
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ Order `attr_writer` arguments alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class User
            attr_reader :apple, :zebra
            attr_writer :bravo, :delta
          end
        RUBY
      end

      it "registers offenses for each declaration" do
        expect_offense(offense_code)
      end

      it "autocorrects each declaration independently" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when some arguments are already in correct position" do
      let(:offense_code) do
        <<~RUBY
          class User
            attr_reader :bravo, :alpha, :charlie
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Order `attr_reader` arguments alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class User
            attr_reader :alpha, :bravo, :charlie
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects while preserving correctly positioned arguments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with completely reversed order" do
      let(:offense_code) do
        <<~RUBY
          class User
            attr_reader :delta, :charlie, :bravo, :alpha
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Order `attr_reader` arguments alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class User
            attr_reader :alpha, :bravo, :charlie, :delta
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects all arguments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end
  end
end
