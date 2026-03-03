# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::ValidateAfterValidates, :config do
  describe "#on_class" do
    context "when a validate call appears before a validates declaration" do
      let(:offense_code) do
        <<~RUBY
          class User < ApplicationRecord
            validate :check
            ^^^^^^^^^^^^^^^ Place `validate` calls after `validates` declarations.
            validates :name
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class User < ApplicationRecord
            validates :name
            validate :check
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by moving validate after validates" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when validate calls appear after validates declarations" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            validates :name
            validate :check
          end
        RUBY
      end
    end

    context "when there are only validate calls in the group" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            validate :check
            validate :ensure
          end
        RUBY
      end
    end

    context "when there are only validates declarations in the group" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            validates :age
            validates :name
          end
        RUBY
      end
    end

    context "when validate and validates are separated by a blank line" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            validate :check

            validates :name
          end
        RUBY
      end
    end

    context "when validate and validates are separated by a non-family statement" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            validate :check
            has_many :posts
            validates :name
          end
        RUBY
      end
    end

    context "when validate and validates are separated by a block statement" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            validate :check
            before_validation { normalize_name }
            validates :name
          end
        RUBY
      end
    end

    context "when class is not a Rails model" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < SomeOtherBase
            validate :check
            validates :name
          end
        RUBY
      end
    end

    context "when class has no parent" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User
            validate :check
            validates :name
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

    context "when class body has only one statement" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            validate :check
          end
        RUBY
      end
    end

    context "with multiple validate calls before validates" do
      let(:offense_code) do
        <<~RUBY
          class User < ApplicationRecord
            validate :check
            ^^^^^^^^^^^^^^^ Place `validate` calls after `validates` declarations.
            validate :ensure
            ^^^^^^^^^^^^^^^^ Place `validate` calls after `validates` declarations.
            validates :name
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class User < ApplicationRecord
            validates :name
            validate :check
            validate :ensure
          end
        RUBY
      end

      it "registers an offense for each misplaced validate" do
        expect_offense(offense_code)
      end

      it "autocorrects by moving all validate calls after validates, preserving their order" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with a mixed group where some nodes are already in the correct position" do
      let(:offense_code) do
        <<~RUBY
          class User < ApplicationRecord
            validates :name
            validate :check
            ^^^^^^^^^^^^^^^ Place `validate` calls after `validates` declarations.
            validates :age
            validate :ensure
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          class User < ApplicationRecord
            validates :name
            validates :age
            validate :check
            validate :ensure
          end
        RUBY
      end

      it "registers an offense for the misplaced validate" do
        expect_offense(offense_code)
      end

      it "autocorrects while leaving already-correct nodes in place" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "with ActiveRecord::Base inheritance" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class User < ActiveRecord::Base
            validate :check
            ^^^^^^^^^^^^^^^ Place `validate` calls after `validates` declarations.
            validates :name
          end
        RUBY
      end
    end

    context "with namespaced ApplicationRecord inheritance" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class User < MyEngine::ApplicationRecord
            validate :check
            ^^^^^^^^^^^^^^^ Place `validate` calls after `validates` declarations.
            validates :name
          end
        RUBY
      end
    end
  end
end
