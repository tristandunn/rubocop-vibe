# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::ValidatesAlphaOrder, :config do
  describe "#on_class" do
    context "when consecutive validates declarations are not alphabetically ordered" do
      let(:offense_code) do
        <<~RUBY
          class User < ApplicationRecord
            validates :name
            validates :age
            ^^^^^^^^^^^^^^ Order validates declarations alphabetically by attribute name.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class User < ApplicationRecord
            validates :age
            validates :name
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by reordering validates declarations" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when consecutive validates declarations are already alphabetically ordered" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            validates :age
            validates :name
          end
        RUBY
      end
    end

    context "when validates declarations are separated by blank lines" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            validates :name

            validates :age
          end
        RUBY
      end
    end

    context "when there is only one validates declaration" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            validates :name
          end
        RUBY
      end
    end

    context "when class body has only one statement total" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            validates :name, presence: true
          end
        RUBY
      end
    end

    context "when validates declarations are separated by a non-validates statement" do
      it "does not register an offense across groups" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            validates :name
            has_many :posts
            validates :age
          end
        RUBY
      end
    end

    context "when validates declarations are separated by a def statement" do
      it "does not register an offense across groups" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            validates :name
            def foo; end
            validates :age
          end
        RUBY
      end
    end

    context "when validates has a receiver" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            Foo.validates :name
            Foo.validates :age
          end
        RUBY
      end
    end

    context "when class is not a Rails model" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < SomeOtherBase
            validates :name
            validates :age
          end
        RUBY
      end
    end

    context "when class has no parent" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User
            validates :name
            validates :age
          end
        RUBY
      end
    end

    context "when class has a non-constant parent" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < base_class
            validates :name
            validates :age
          end
        RUBY
      end
    end

    context "when class body is empty" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
          end
        RUBY
      end
    end

    context "with validates in separate groups divided by a blank line" do
      let(:offense_code) do
        <<~RUBY
          class User < ApplicationRecord
            validates :name
            validates :age
            ^^^^^^^^^^^^^^ Order validates declarations alphabetically by attribute name.

            validates :title
            validates :body
            ^^^^^^^^^^^^^^^ Order validates declarations alphabetically by attribute name.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class User < ApplicationRecord
            validates :age
            validates :name

            validates :body
            validates :title
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

    context "with multiple violations in the same group" do
      let(:offense_code) do
        <<~RUBY
          class User < ApplicationRecord
            validates :name
            validates :email
            ^^^^^^^^^^^^^^^^ Order validates declarations alphabetically by attribute name.
            validates :body
            ^^^^^^^^^^^^^^^ Order validates declarations alphabetically by attribute name.
            validates :age
            ^^^^^^^^^^^^^^ Order validates declarations alphabetically by attribute name.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class User < ApplicationRecord
            validates :age
            validates :body
            validates :email
            validates :name
          end
        RUBY
      end

      it "registers an offense for each out-of-order validates" do
        expect_offense(offense_code)
      end

      it "autocorrects all declarations" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when some validates are already in correct position" do
      let(:offense_code) do
        <<~RUBY
          class User < ApplicationRecord
            validates :age
            validates :name
            validates :email
            ^^^^^^^^^^^^^^^^ Order validates declarations alphabetically by attribute name.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class User < ApplicationRecord
            validates :age
            validates :email
            validates :name
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects while leaving correctly positioned validates unchanged" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with different validates methods" do
      let(:offense_code) do
        <<~RUBY
          class User < ApplicationRecord
            validates_presence_of :name
            validates_numericality_of :age
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Order validates declarations alphabetically by attribute name.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class User < ApplicationRecord
            validates_numericality_of :age
            validates_presence_of :name
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by reordering" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with ActiveRecord::Base inheritance" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class User < ActiveRecord::Base
            validates :name
            validates :age
            ^^^^^^^^^^^^^^ Order validates declarations alphabetically by attribute name.
          end
        RUBY
      end
    end

    context "with namespaced ApplicationRecord inheritance" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class User < MyEngine::ApplicationRecord
            validates :name
            validates :age
            ^^^^^^^^^^^^^^ Order validates declarations alphabetically by attribute name.
          end
        RUBY
      end
    end
  end
end
