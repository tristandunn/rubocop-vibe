# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::ServiceCallMethod, :config do
  describe "#on_class" do
    context "when class has both self.call and call methods" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "app/services/my_service.rb")
          class MyService
            def self.call(arg)
              new(arg).call
            end

            def call
              # implementation
            end
          end
        RUBY
      end
    end

    context "when class has both methods in nested module" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "app/services/monsters/attack.rb")
          module Monsters
            class Attack
              def self.call(monster)
                new(monster).call
              end

              def call
                # implementation
              end
            end
          end
        RUBY
      end
    end

    context "when class is missing self.call method" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "app/services/my_service.rb")
          class MyService
                ^^^^^^^^^ Service objects should define `self.call` and `call` methods.
            def call
              # implementation
            end
          end
        RUBY
      end
    end

    context "when class is missing instance call method" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "app/services/my_service.rb")
          class MyService
                ^^^^^^^^^ Service objects should define `self.call` and `call` methods.
            def self.call(arg)
              # implementation
            end
          end
        RUBY
      end
    end

    context "when class is missing both methods" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "app/services/my_service.rb")
          class MyService
                ^^^^^^^^^ Service objects should define `self.call` and `call` methods.
            def perform
              # implementation
            end
          end
        RUBY
      end
    end

    context "when file is not in app/services/" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "app/models/user.rb")
          class User
            def perform
              # implementation
            end
          end
        RUBY
      end
    end

    context "when file is in nested services directory" do
      it "registers an offense for missing methods" do
        expect_offense(<<~RUBY, "app/services/commands/say.rb")
          module Commands
            class Say
                  ^^^ Service objects should define `self.call` and `call` methods.
              def perform
                # implementation
              end
            end
          end
        RUBY
      end
    end

    context "when module is defined instead of class" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "app/services/my_module.rb")
          module MyModule
            def self.included(base)
              # implementation
            end
          end
        RUBY
      end
    end

    context "when class is empty" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "app/services/empty_service.rb")
          class EmptyService
                ^^^^^^^^^^^^ Service objects should define `self.call` and `call` methods.
          end
        RUBY
      end
    end

    context "when class has multiple methods including both call methods" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "app/services/my_service.rb")
          class MyService
            def self.call(arg)
              new(arg).call
            end

            def self.other_method
              # implementation
            end

            def call
              # implementation
            end

            def helper
              # implementation
            end
          end
        RUBY
      end
    end
  end
end
