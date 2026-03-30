# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::ModuleOrganization, :config do
  describe "#on_module" do
    context "when module elements are in correct order" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          module Helper
            include Foo
            extend Bar

            CONSTANT = 1

            attr_accessor :name
            attr_reader :age

            def self.build
              new
            end

            def alpha
              "a"
            end

            def beta
              "b"
            end

            protected

            def gamma
              "g"
            end

            private

            def delta
              "d"
            end
          end
        RUBY
      end
    end

    context "when module has no body" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          module Empty
          end
        RUBY
      end
    end

    context "when module has a single element" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          module Helper
            def call
              "hello"
            end
          end
        RUBY
      end
    end

    context "when methods are not in alphabetical order" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          module Helper
            def zebra
              "z"
            end

            def alpha
            ^^^^^^^^^ Module elements should be ordered: includes/extends → constants → attr → class methods → instance methods → protected → private.
              "a"
            end
          end
        RUBY
      end

      it "autocorrects by reordering methods" do
        expect_offense(<<~RUBY)
          module Helper
            def zebra
              "z"
            end

            def alpha
            ^^^^^^^^^ Module elements should be ordered: includes/extends → constants → attr → class methods → instance methods → protected → private.
              "a"
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          module Helper
            def alpha
              "a"
            end

            def zebra
              "z"
            end
          end
        RUBY
      end
    end

    context "when include comes after a method" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          module Helper
            def call
              "hello"
            end

            include Foo
            ^^^^^^^^^^^ Module elements should be ordered: includes/extends → constants → attr → class methods → instance methods → protected → private.
          end
        RUBY
      end

      it "autocorrects by moving include before methods" do
        expect_offense(<<~RUBY)
          module Helper
            def call
              "hello"
            end

            include Foo
            ^^^^^^^^^^^ Module elements should be ordered: includes/extends → constants → attr → class methods → instance methods → protected → private.
          end
        RUBY

        expect_correction(<<~RUBY)
          module Helper
            include Foo

            def call
              "hello"
            end
          end
        RUBY
      end
    end

    context "when extend comes after a method" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          module Helper
            def call
              "hello"
            end

            extend Bar
            ^^^^^^^^^^ Module elements should be ordered: includes/extends → constants → attr → class methods → instance methods → protected → private.
          end
        RUBY
      end
    end

    context "when constant comes after a method" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          module Helper
            def call
              "hello"
            end

            CONSTANT = 1
            ^^^^^^^^^^^^ Module elements should be ordered: includes/extends → constants → attr → class methods → instance methods → protected → private.
          end
        RUBY
      end
    end

    context "when attr comes after a method" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          module Helper
            def call
              "hello"
            end

            attr_reader :name
            ^^^^^^^^^^^^^^^^^ Module elements should be ordered: includes/extends → constants → attr → class methods → instance methods → protected → private.
          end
        RUBY
      end
    end

    context "when instance method comes before class method" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          module Helper
            def instance_method
              "hello"
            end

            def self.class_method
            ^^^^^^^^^^^^^^^^^^^^^ Module elements should be ordered: includes/extends → constants → attr → class methods → instance methods → protected → private.
              "hello"
            end
          end
        RUBY
      end
    end

    context "when private methods are not in alphabetical order" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          module Helper
            private

            def zebra
              "z"
            end

            def alpha
            ^^^^^^^^^ Module elements should be ordered: includes/extends → constants → attr → class methods → instance methods → protected → private.
              "a"
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          module Helper
            private

            def alpha
              "a"
            end

            def zebra
              "z"
            end
          end
        RUBY
      end
    end

    context "when protected methods are not in alphabetical order" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          module Helper
            protected

            def zebra
              "z"
            end

            def alpha
            ^^^^^^^^^ Module elements should be ordered: includes/extends → constants → attr → class methods → instance methods → protected → private.
              "a"
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          module Helper
            protected

            def alpha
              "a"
            end

            def zebra
              "z"
            end
          end
        RUBY
      end
    end

    context "when private comes before protected" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          module Helper
            private

            def secret
              "secret"
            end

            protected

            def guarded
            ^^^^^^^^^^^ Module elements should be ordered: includes/extends → constants → attr → class methods → instance methods → protected → private.
              "guarded"
            end
          end
        RUBY
      end
    end

    context "when comments are preserved during autocorrect" do
      it "moves comments with their methods" do
        expect_offense(<<~RUBY)
          module Helper
            # Zebra method.
            def zebra
              "z"
            end

            # Alpha method.
            def alpha
            ^^^^^^^^^ Module elements should be ordered: includes/extends → constants → attr → class methods → instance methods → protected → private.
              "a"
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          module Helper
            # Alpha method.
            def alpha
              "a"
            end

            # Zebra method.
            def zebra
              "z"
            end
          end
        RUBY
      end
    end

    context "when attr methods are ordered with instance methods" do
      it "sorts attr before regular methods in private" do
        expect_offense(<<~RUBY)
          module Helper
            private

            def alpha
              "a"
            end

            attr_reader :name
            ^^^^^^^^^^^^^^^^^ Module elements should be ordered: includes/extends → constants → attr → class methods → instance methods → protected → private.
          end
        RUBY

        expect_correction(<<~RUBY)
          module Helper
            private

            attr_reader :name

            def alpha
              "a"
            end
          end
        RUBY
      end
    end

    context "when module has unrecognized send nodes" do
      it "ignores unrecognized sends" do
        expect_no_offenses(<<~RUBY)
          module Helper
            delegate :name, to: :user

            def call
              "hello"
            end
          end
        RUBY
      end
    end

    context "when module has full correct ordering" do
      it "does not register an offense with all categories" do
        expect_no_offenses(<<~RUBY)
          module Helper
            include Foo
            extend Bar

            CONSTANT_A = 1
            CONSTANT_B = 2

            attr_accessor :name
            attr_reader :age
            attr_writer :email

            def self.build
              new
            end

            def self.create
              new
            end

            def alpha
              "a"
            end

            def beta
              "b"
            end

            protected

            def gamma
              "g"
            end

            private

            def delta
              "d"
            end

            def epsilon
              "e"
            end
          end
        RUBY
      end
    end

    context "when module has complex reordering" do
      it "autocorrects multiple violations" do
        expect_offense(<<~RUBY)
          module Helper
            def zebra
              "z"
            end

            CONSTANT = 1
            ^^^^^^^^^^^^ Module elements should be ordered: includes/extends → constants → attr → class methods → instance methods → protected → private.

            def alpha
              "a"
            end

            include Foo
          end
        RUBY

        expect_correction(<<~RUBY)
          module Helper
            include Foo

            CONSTANT = 1

            def alpha
              "a"
            end

            def zebra
              "z"
            end
          end
        RUBY
      end
    end

    context "when module body is a single non-begin node" do
      it "does not register an offense for single method" do
        expect_no_offenses(<<~RUBY)
          module Helper
            CONSTANT = 1
          end
        RUBY
      end
    end

    context "when class methods are not in alphabetical order" do
      it "registers an offense and autocorrects" do
        expect_offense(<<~RUBY)
          module Helper
            def self.zebra
              "z"
            end

            def self.alpha
            ^^^^^^^^^^^^^^ Module elements should be ordered: includes/extends → constants → attr → class methods → instance methods → protected → private.
              "a"
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          module Helper
            def self.alpha
              "a"
            end

            def self.zebra
              "z"
            end
          end
        RUBY
      end
    end
  end
end
