# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::NoCompoundConditions, :config do
  describe "#on_and / #on_or" do
    context "with && compound condition in if" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          if user.active? && user.verified?
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
            grant_access
          end
        RUBY
      end
    end

    context "with || compound condition in if" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          if admin? || moderator?
             ^^^^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
            allow
          end
        RUBY
      end
    end

    context "with mixed && and || operators" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          if active? && verified? || admin?
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
             ^^^^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
            proceed
          end
        RUBY
      end
    end

    context "with three or more conditions" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          if a? && b? && c?
             ^^^^^^^^^^^^^^ Extract compound conditions into a named method.
             ^^^^^^^^ Extract compound conditions into a named method.
            do_something
          end
        RUBY
      end
    end

    context "with unless statement" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          unless order.paid? && order.shipped?
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
            send_reminder
          end
        RUBY
      end
    end

    context "with modifier if" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          do_something if active? && verified?
                          ^^^^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
        RUBY
      end
    end

    context "with modifier unless" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          return unless valid? || forced?
                        ^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
        RUBY
      end
    end

    context "with ternary operator" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          active? && verified? ? "yes" : "no"
          ^^^^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
        RUBY
      end
    end

    context "with while loop" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          while active? && running?
                ^^^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
            do_work
          end
        RUBY
      end
    end

    context "with until loop" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          until finished? || cancelled?
                ^^^^^^^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
            process
          end
        RUBY
      end
    end

    context "with modifier while" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          do_work while active? && running?
                        ^^^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
        RUBY
      end
    end

    context "with modifier until" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          process until finished? || cancelled?
                        ^^^^^^^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
        RUBY
      end
    end

    context "with negated compound condition" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          if !(active? && verified?)
               ^^^^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
            deny
          end
        RUBY
      end
    end

    context "with negation inside compound condition" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          if !active? && !verified?
             ^^^^^^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
            deny
          end
        RUBY
      end
    end

    context "with single condition" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          if user.active?
            do_something
          end
        RUBY
      end
    end

    context "with single negated condition" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          if !user.banned?
            allow
          end
        RUBY
      end
    end

    context "with safe navigation" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          if user&.subscription&.active?
            grant_access
          end
        RUBY
      end
    end

    context "with elsif containing compound condition" do
      it "registers an offense for the elsif" do
        expect_offense(<<~RUBY)
          if simple?
            one
          elsif complex? && valid?
                ^^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
            two
          end
        RUBY
      end
    end

    context "with compound condition in when clause" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          case status
          when active? && verified?
               ^^^^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
            proceed
          end
        RUBY
      end
    end

    context "with multiple when conditions (comma-separated)" do
      it "does not register an offense for simple conditions" do
        expect_no_offenses(<<~RUBY)
          case status
          when :active, :pending
            proceed
          end
        RUBY
      end
    end

    context "with simple when condition" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          case status
          when active?
            proceed
          end
        RUBY
      end
    end

    context "when compound is the return value of a method" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def can_participate?
            user.active? && user.verified?
          end
        RUBY
      end
    end

    context "when compound is the return value with other code before" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def can_participate?
            do_something
            user.active? && user.verified?
          end
        RUBY
      end
    end

    context "when compound is inside explicit return" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def can_participate?
            return admin? || moderator? if override?
                   ^^^^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
            false
          end
        RUBY
      end
    end

    context "when compound is class method return value" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def self.can_participate?
            user.active? && user.verified?
          end
        RUBY
      end
    end

    context "when compound is in a method but used in conditional" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def process
            if active? && verified?
               ^^^^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
              do_work
            end
          end
        RUBY
      end
    end

    context "when compound is NOT the last expression" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def process
            if active? && verified?
               ^^^^^^^^^^^^^^^^^^^^ Extract compound conditions into a named method.
              do_work
            end
            cleanup
          end
        RUBY
      end
    end

    context "with compound in if body as return value" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def can_access?
            if special_case?
              admin? || moderator?
            else
              user.active? && user.verified?
            end
          end
        RUBY
      end
    end

    context "with compound in block" do
      it "does not register an offense for select block" do
        expect_no_offenses(<<~RUBY)
          items.select { |item| item.active? && item.valid? }
        RUBY
      end
    end

    context "with compound in assignment" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          result = active? && verified?
        RUBY
      end
    end
  end
end
