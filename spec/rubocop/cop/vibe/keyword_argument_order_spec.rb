# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::KeywordArgumentOrder, :config do
  describe "#on_def" do
    context "when keyword arguments are not alphabetically ordered" do
      let(:offense_code) do
        <<~RUBY
          def initialize(id:, content:, timestamp:, raw: nil)
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Order keyword arguments alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def initialize(content:, id:, timestamp:, raw: nil)
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

    context "when keyword arguments are alphabetically ordered" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def initialize(content:, id:, timestamp:, raw: nil)
          end
        RUBY
      end
    end

    context "when there is only one keyword argument" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def initialize(id:)
          end
        RUBY
      end
    end

    context "when method has no keyword arguments" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def initialize(id, content)
          end
        RUBY
      end
    end

    context "when method has no arguments" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def initialize
          end
        RUBY
      end
    end

    context "when method has mixed positional and keyword arguments" do
      let(:offense_code) do
        <<~RUBY
          def call(name, zebra:, apple:)
                  ^^^^^^^^^^^^^^^^^^^^^^ Order keyword arguments alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def call(name, apple:, zebra:)
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects while preserving positional argument position" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when method has YARD documentation" do
      let(:offense_code) do
        <<~RUBY
          # Initializes a new message.
          #
          # @param id [String] the identifier
          # @param content [String] the body
          def initialize(id:, content:)
                        ^^^^^^^^^^^^^^^ Order keyword arguments alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          # Initializes a new message.
          #
          # @param content [String] the body
          # @param id [String] the identifier
          def initialize(content:, id:)
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects both arguments and documentation" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when method has YARD documentation with multiple params" do
      let(:offense_code) do
        <<~RUBY
          # Initializes a new incoming message.
          #
          # @param id [String] the unique message identifier
          # @param content [String] the message body
          # @param timestamp [Time] when the message was created
          # @param raw [Hash, nil] the original payload
          def initialize(id:, content:, timestamp:, raw: nil)
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Order keyword arguments alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          # Initializes a new incoming message.
          #
          # @param content [String] the message body
          # @param id [String] the unique message identifier
          # @param timestamp [Time] when the message was created
          # @param raw [Hash, nil] the original payload
          def initialize(content:, id:, timestamp:, raw: nil)
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects all arguments and documentation" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when YARD documentation has non-param comments" do
      let(:offense_code) do
        <<~RUBY
          # Creates a user.
          #
          # @param name [String] the name
          # @param age [Integer] the age
          # @return [User] the new user
          def create(name:, age:)
                    ^^^^^^^^^^^^^ Order keyword arguments alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          # Creates a user.
          #
          # @param age [Integer] the age
          # @param name [String] the name
          # @return [User] the new user
          def create(age:, name:)
          end
        RUBY
      end

      it "autocorrects only param comments for keyword arguments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when method has no documentation" do
      let(:offense_code) do
        <<~RUBY
          def initialize(zebra:, apple:)
                        ^^^^^^^^^^^^^^^^ Order keyword arguments alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def initialize(apple:, zebra:)
          end
        RUBY
      end

      it "autocorrects arguments only" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when method has comments but no @param tags for kwargs" do
      let(:offense_code) do
        <<~RUBY
          # This method does something.
          # @return [Boolean] true if successful
          def call(zebra:, apple:)
                  ^^^^^^^^^^^^^^^^ Order keyword arguments alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          # This method does something.
          # @return [Boolean] true if successful
          def call(apple:, zebra:)
          end
        RUBY
      end

      it "autocorrects arguments only without modifying comments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with class method definition" do
      let(:offense_code) do
        <<~RUBY
          def self.call(zebra:, apple:)
                       ^^^^^^^^^^^^^^^^ Order keyword arguments alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def self.call(apple:, zebra:)
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects class method arguments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when two keyword arguments are out of order" do
      let(:offense_code) do
        <<~RUBY
          def call(bb:, aa:)
                  ^^^^^^^^^^ Order keyword arguments alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def call(aa:, bb:)
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

    context "when only optional keyword arguments are present" do
      let(:offense_code) do
        <<~RUBY
          def call(zebra: nil, apple: nil)
                  ^^^^^^^^^^^^^^^^^^^^^^^^ Order keyword arguments alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def call(apple: nil, zebra: nil)
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects optional keyword arguments" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when YARD has params for positional args mixed with keyword args" do
      let(:offense_code) do
        <<~RUBY
          # Does something.
          #
          # @param name [String] the name
          # @param zebra [String] a zebra
          # @param apple [String] an apple
          def call(name, zebra:, apple:)
                  ^^^^^^^^^^^^^^^^^^^^^^ Order keyword arguments alphabetically.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          # Does something.
          #
          # @param name [String] the name
          # @param apple [String] an apple
          # @param zebra [String] a zebra
          def call(name, apple:, zebra:)
          end
        RUBY
      end

      it "autocorrects only keyword argument params" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end
  end
end
