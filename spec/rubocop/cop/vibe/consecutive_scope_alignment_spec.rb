# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::ConsecutiveScopeAlignment, :config do
  describe "#on_class" do
    context "when consecutive scope declarations are not aligned" do
      let(:offense_code) do
        <<~RUBY
          class PageView
            scope :between, ->(start, stop) { where(created_at: start..stop) }
                  ^^^^^^^^ Align consecutive scope declarations at the `->` arrow.
            scope :for_website, ->(website_id) { where(website_id: website_id) }
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class PageView
            scope :between,     ->(start, stop) { where(created_at: start..stop) }
            scope :for_website, ->(website_id) { where(website_id: website_id) }
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning scope declarations" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when consecutive scope declarations are already aligned" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class PageView
            scope :between,     ->(start, stop) { where(created_at: start..stop) }
            scope :for_website, ->(website_id)  { where(website_id: website_id) }
          end
        RUBY
      end
    end

    context "when scope declarations are separated by blank lines" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class PageView
            scope :between,     ->(start, stop) { where(created_at: start..stop) }

            scope :for_website, ->(website_id) { where(website_id: website_id) }
          end
        RUBY
      end
    end

    context "when there is only one scope declaration" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class PageView
            scope :between, ->(start, stop) { where(created_at: start..stop) }
          end
        RUBY
      end
    end

    context "when scope declarations are in separate groups" do
      let(:offense_code) do
        <<~RUBY
          class PageView
            scope :active, -> { where(active: true) }
                  ^^^^^^^ Align consecutive scope declarations at the `->` arrow.
            scope :for_website, ->(website_id) { where(website_id: website_id) }

            scope :between, ->(start, stop) { where(created_at: start..stop) }
            scope :recent, ->(limit) { order(created_at: :desc).limit(limit) }
                  ^^^^^^^ Align consecutive scope declarations at the `->` arrow.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class PageView
            scope :active,      -> { where(active: true) }
            scope :for_website, ->(website_id) { where(website_id: website_id) }

            scope :between, ->(start, stop) { where(created_at: start..stop) }
            scope :recent,  ->(limit) { order(created_at: :desc).limit(limit) }
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

    context "when non-scope statements break up scope declarations" do
      it "does not register an offense for separated scope declarations" do
        expect_no_offenses(<<~RUBY)
          class PageView
            scope :between, ->(start, stop) { where(created_at: start..stop) }

            belongs_to :website

            scope :for_website, ->(website_id) { where(website_id: website_id) }
          end
        RUBY
      end
    end

    context "when there are two consecutive scope declarations" do
      let(:offense_code) do
        <<~RUBY
          class PageView
            scope :a, -> { where(a: true) }
                  ^^ Align consecutive scope declarations at the `->` arrow.
            scope :bb, -> { where(bb: true) }
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class PageView
            scope :a,  -> { where(a: true) }
            scope :bb, -> { where(bb: true) }
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning scope declarations" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when autocorrecting ensures proper spacing for large gaps" do
      let(:offense_code) do
        <<~RUBY
          class PageView
            scope :very_long_scope_name, ->(x) { where(x: x) }
            scope :x, ->(y) { where(y: y) }
                  ^^ Align consecutive scope declarations at the `->` arrow.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class PageView
            scope :very_long_scope_name, ->(x) { where(x: x) }
            scope :x,                    ->(y) { where(y: y) }
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

    context "when scope uses a proc instead of a lambda" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class PageView
            scope :active, proc { where(active: true) }
            scope :inactive, proc { where(active: false) }
          end
        RUBY
      end
    end

    context "when scope uses a symbol reference instead of a lambda" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class PageView
            scope :active, :active_scope
            scope :inactive, :inactive_scope
          end
        RUBY
      end
    end

    context "when scope declarations include no-arg lambdas mixed with arg lambdas" do
      let(:offense_code) do
        <<~RUBY
          class PageView
            scope :active, -> { where(active: true) }
                  ^^^^^^^ Align consecutive scope declarations at the `->` arrow.
            scope :for_website, ->(website_id) { where(website_id: website_id) }
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class PageView
            scope :active,      -> { where(active: true) }
            scope :for_website, ->(website_id) { where(website_id: website_id) }
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by aligning scope declarations" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when class body is empty" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class PageView
          end
        RUBY
      end
    end

    context "when class body contains non-send statements alongside scopes" do
      it "does not register an offense for the non-send statement" do
        expect_no_offenses(<<~RUBY)
          class PageView
            VALID_STATUSES = %w(active inactive).freeze

            scope :active,   -> { where(active: true) }
            scope :inactive, -> { where(active: false) }
          end
        RUBY
      end
    end

    context "when scope is called on a receiver" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class PageView
            SomeModule.scope :active, ->(x) { where(active: x) }
            SomeModule.scope :inactive, ->(x) { where(active: !x) }
          end
        RUBY
      end
    end

    context "when scope has no second argument" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class PageView
            scope :active
            scope :inactive
          end
        RUBY
      end
    end
  end
end
