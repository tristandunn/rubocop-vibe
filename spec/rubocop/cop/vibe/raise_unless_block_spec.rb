# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::RaiseUnlessBlock, :config do
  describe "#on_if" do
    context "when using raise with unless modifier" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          raise ArgumentError, "Invalid column" unless COLUMNS.include?(column)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `if/end` block instead of inline modifier for `raise`.
        RUBY

        expect_correction(<<~RUBY)
          if !COLUMNS.include?(column)
            raise ArgumentError, "Invalid column"
          end
        RUBY
      end
    end

    context "when using raise with unless modifier and exception only" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          raise ArgumentError unless valid?
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `if/end` block instead of inline modifier for `raise`.
        RUBY

        expect_correction(<<~RUBY)
          if !valid?
            raise ArgumentError
          end
        RUBY
      end
    end

    context "when using raise with unless modifier and interpolated message" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~'RUBY')
          raise ArgumentError, "Invalid column: #{column}" unless GROUPABLE_COLUMNS.include?(column.to_s)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `if/end` block instead of inline modifier for `raise`.
        RUBY

        expect_correction(<<~'RUBY')
          if !GROUPABLE_COLUMNS.include?(column.to_s)
            raise ArgumentError, "Invalid column: #{column}"
          end
        RUBY
      end
    end

    context "when using raise with unless modifier and complex condition" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          raise ArgumentError unless valid? && active? && enabled?
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `if/end` block instead of inline modifier for `raise`.
        RUBY

        expect_correction(<<~RUBY)
          if !valid? && active? && enabled?
            raise ArgumentError
          end
        RUBY
      end
    end

    context "when using raise with if modifier" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          raise ArgumentError, "Invalid column" if column.nil?
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `if/end` block instead of inline modifier for `raise`.
        RUBY

        expect_correction(<<~RUBY)
          if column.nil?
            raise ArgumentError, "Invalid column"
          end
        RUBY
      end
    end

    context "when using raise with if modifier and complex condition" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          raise ArgumentError if invalid? || disabled?
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `if/end` block instead of inline modifier for `raise`.
        RUBY

        expect_correction(<<~RUBY)
          if invalid? || disabled?
            raise ArgumentError
          end
        RUBY
      end
    end

    context "when raise with if modifier is inside a method" do
      it "registers an offense and autocorrects with proper indentation" do
        expect_offense(<<~RUBY)
          def validate_column(column)
            raise ArgumentError if column.nil?
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `if/end` block instead of inline modifier for `raise`.
          end
        RUBY

        expect_correction(<<~RUBY)
          def validate_column(column)
            if column.nil?
              raise ArgumentError
            end
          end
        RUBY
      end
    end

    context "when using raise without modifier" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          raise ArgumentError, "Invalid column"
        RUBY
      end
    end

    context "when using raise in an unless block" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          unless valid?
            raise ArgumentError
          end
        RUBY
      end
    end

    context "when using raise in an if block" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          if !valid?
            raise ArgumentError
          end
        RUBY
      end
    end

    context "when raise with unless is inside a method" do
      it "registers an offense and autocorrects with proper indentation" do
        expect_offense(<<~RUBY)
          def validate_column(column)
            raise ArgumentError unless COLUMNS.include?(column)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `if/end` block instead of inline modifier for `raise`.
          end
        RUBY

        expect_correction(<<~RUBY)
          def validate_column(column)
            if !COLUMNS.include?(column)
              raise ArgumentError
            end
          end
        RUBY
      end
    end

    context "when raise is deeply nested" do
      it "registers an offense and autocorrects with proper indentation" do
        expect_offense(<<~RUBY)
          class Validator
            def validate
              items.each do |item|
                raise ArgumentError unless item.valid?
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `if/end` block instead of inline modifier for `raise`.
              end
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          class Validator
            def validate
              items.each do |item|
                if !item.valid?
                  raise ArgumentError
                end
              end
            end
          end
        RUBY
      end
    end

    context "when using raise with a string message only" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          raise "Something went wrong" unless condition
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `if/end` block instead of inline modifier for `raise`.
        RUBY

        expect_correction(<<~RUBY)
          if !condition
            raise "Something went wrong"
          end
        RUBY
      end
    end

    context "when using raise with exception and backtrace" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          raise ArgumentError.new("message"), cause.backtrace unless valid?
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `if/end` block instead of inline modifier for `raise`.
        RUBY

        expect_correction(<<~RUBY)
          if !valid?
            raise ArgumentError.new("message"), cause.backtrace
          end
        RUBY
      end
    end

    context "when using fail instead of raise" do
      it "does not register an offense (only handles raise)" do
        expect_no_offenses(<<~RUBY)
          fail ArgumentError unless valid?
        RUBY
      end
    end

    context "when unless modifier is on a non-raise statement" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          return unless valid?
        RUBY
      end
    end

    context "when if modifier is on a non-raise statement" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          return if invalid?
        RUBY
      end
    end

    context "when raise has parentheses around arguments" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          raise(ArgumentError, "Invalid") unless valid?
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `if/end` block instead of inline modifier for `raise`.
        RUBY

        expect_correction(<<~RUBY)
          if !valid?
            raise(ArgumentError, "Invalid")
          end
        RUBY
      end
    end
  end
end
