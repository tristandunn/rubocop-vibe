# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::NoSingleCharacterVariableNames, :config do
  let(:allowed_names) { ["_"] }
  let(:cop_config)    { { "AllowedNames" => allowed_names } }

  describe "local variables" do
    context "with a single character name" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          x = 1
          ^ Avoid single character variable name `x`.
        RUBY
      end
    end

    context "with a multi-character name" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          name = 1
        RUBY
      end
    end

    context "with an allowed single character name" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          _ = 1
        RUBY
      end
    end
  end

  describe "instance variables" do
    context "with a single character name" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          @a = 1
          ^^ Avoid single character variable name `@a`.
        RUBY
      end
    end

    context "with a multi-character name" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          @name = 1
        RUBY
      end
    end
  end

  describe "class variables" do
    context "with a single character name" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          @@a = 1
          ^^^ Avoid single character variable name `@@a`.
        RUBY
      end
    end

    context "with a multi-character name" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          @@name = 1
        RUBY
      end
    end
  end

  describe "method parameters" do
    context "with a single character positional argument" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def foo(x)
                  ^ Avoid single character variable name `x`.
          end
        RUBY
      end
    end

    context "with a single character optional argument" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def foo(x = 1)
                  ^ Avoid single character variable name `x`.
          end
        RUBY
      end
    end

    context "with a single character keyword argument" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def foo(x:)
                  ^ Avoid single character variable name `x`.
          end
        RUBY
      end
    end

    context "with a single character optional keyword argument" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def foo(x: 1)
                  ^ Avoid single character variable name `x`.
          end
        RUBY
      end
    end

    context "with a single character rest argument" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def foo(*x)
                   ^ Avoid single character variable name `x`.
          end
        RUBY
      end
    end

    context "with an anonymous rest argument" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def foo(*)
          end
        RUBY
      end
    end

    context "with a single character keyword rest argument" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def foo(**x)
                    ^ Avoid single character variable name `x`.
          end
        RUBY
      end
    end

    context "with a single character block argument" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def foo(&x)
                   ^ Avoid single character variable name `x`.
          end
        RUBY
      end
    end

    context "with a multi-character argument" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def foo(name)
          end
        RUBY
      end
    end
  end

  describe "block parameters" do
    context "with a single character name" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          [1].each { |x| x }
                      ^ Avoid single character variable name `x`.
        RUBY
      end
    end

    context "with a multi-character name" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          [1].each { |item| item }
        RUBY
      end
    end
  end

  describe "rescue variable" do
    context "with a single character name" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          begin
            do_something
          rescue => e
                    ^ Avoid single character variable name `e`.
          end
        RUBY
      end
    end
  end

  describe "Rails migration files" do
    context "when the file is under db/" do
      it "does not register an offense for `t`" do
        expect_no_offenses(<<~RUBY, "db/migrate/20260101000000_create_users.rb")
          create_table :users do |t|
            t.string :name
          end
        RUBY
      end

      it "still registers an offense for other single character names" do
        expect_offense(<<~RUBY, "db/migrate/20260101000000_create_users.rb")
          create_table :users do |x|
                                  ^ Avoid single character variable name `x`.
            x.string :name
          end
        RUBY
      end
    end

    context "when the file is not under db/" do
      it "registers an offense for `t`" do
        expect_offense(<<~RUBY, "app/models/user.rb")
          create_table :users do |t|
                                  ^ Avoid single character variable name `t`.
            t.string :name
          end
        RUBY
      end
    end
  end

  describe "AllowedNames configuration" do
    let(:allowed_names) { %w(_ i j) }

    it "does not register an offense for configured names" do
      expect_no_offenses(<<~RUBY)
        i = 0
        j = 1
      RUBY
    end

    it "still registers an offense for non-allowed single characters" do
      expect_offense(<<~RUBY)
        x = 1
        ^ Avoid single character variable name `x`.
      RUBY
    end
  end
end
