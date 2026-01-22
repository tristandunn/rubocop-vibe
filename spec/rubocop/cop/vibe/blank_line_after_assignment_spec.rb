# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::BlankLineAfterAssignment, :config do
  describe "in blocks" do
    context "when assignment is followed by non-assignment without blank line" do
      let(:offense_code) do
        <<~RUBY
          loop do
            deleted_count = delete_batch
            break if deleted_count < BATCH_SIZE
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add a blank line after variable assignment.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          loop do
            deleted_count = delete_batch

            break if deleted_count < BATCH_SIZE
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by adding a blank line" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when assignment is followed by non-assignment with blank line" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          loop do
            deleted_count = delete_batch

            break if deleted_count < BATCH_SIZE
          end
        RUBY
      end
    end

    context "when consecutive assignments exist" do
      it "does not register an offense between assignments" do
        expect_no_offenses(<<~RUBY)
          loop do
            user = find_user
            account = user.account

            process(user, account)
          end
        RUBY
      end

      it "does not register an offense when following assignment has if modifier" do
        expect_no_offenses(<<~RUBY)
          def process
            item = item.split(RANGE_SEPARATOR, 2)
            item = Range.new(*item) if item.size == 2
            item.to_a
          end
        RUBY
      end

      it "does not register an offense when following assignment has unless modifier" do
        expect_no_offenses(<<~RUBY)
          def process
            value = compute
            value = default unless value
            value
          end
        RUBY
      end

      it "does not register an offense when following assignment has while modifier" do
        expect_no_offenses(<<~RUBY)
          def process
            item = queue.pop
            item = queue.pop while item.nil?
            item
          end
        RUBY
      end

      it "does not register an offense when following assignment has until modifier" do
        expect_no_offenses(<<~RUBY)
          def process
            result = attempt
            result = attempt until result
            result
          end
        RUBY
      end
    end

    context "when next line uses the assigned variable" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def process
            forwarded = request.headers["X-Forwarded-For"]
            forwarded.to_s.split(",").first.to_s.strip.presence
          end
        RUBY
      end

      it "does not register an offense for method chains" do
        expect_no_offenses(<<~RUBY)
          def process
            result = calculate
            result.save
          end
        RUBY
      end

      it "does not register an offense when next line operates on the variable with if modifier" do
        expect_no_offenses(<<~RUBY)
          def process
            class_names = [format(CLASS_FORMAT, line: line)]
            class_names << HIGHLIGHT_LINE_CLASS if lines.include?(line)
            class_names.join(SPACE)
          end
        RUBY
      end

      it "does not register an offense when next line operates on the variable with unless modifier" do
        expect_no_offenses(<<~RUBY)
          def process
            items = []
            items << item unless item.nil?
            items
          end
        RUBY
      end
    end

    context "when consecutive FactoryBot calls" do
      it "does not register an offense for create followed by create" do
        expect_no_offenses(<<~RUBY)
          it "works" do
            website   = create(:website)
            page_view = create(:page_view, website: website)
            create(:page_view, website: website)
          end
        RUBY
      end

      it "does not register an offense for mixed factory methods" do
        expect_no_offenses(<<~RUBY)
          it "works" do
            user = build(:user)
            create_list(:post, 3, user: user)
          end
        RUBY
      end

      it "does not register an offense for build_stubbed" do
        expect_no_offenses(<<~RUBY)
          it "works" do
            user = build_stubbed(:user)
            build_stubbed(:account, user: user)
          end
        RUBY
      end

      it "requires blank line when factory call followed by non-send statement" do
        expect_offense(<<~RUBY)
          it "works" do
            user = create(:user)
            if condition?
            ^^^^^^^^^^^^^ Add a blank line after variable assignment.
              process(user)
            end
          end
        RUBY
      end

      it "requires blank line when non-factory assignment followed by factory call" do
        expect_offense(<<~RUBY)
          it "works" do
            user = find_user
            create(:post, user: user)
            ^^^^^^^^^^^^^^^^^^^^^^^^^ Add a blank line after variable assignment.
          end
        RUBY
      end

      it "requires blank line when factory call followed by while loop" do
        expect_offense(<<~RUBY)
          def process
            item = create(:item)
            while processing?
            ^^^^^^^^^^^^^^^^^ Add a blank line after variable assignment.
              work
            end
          end
        RUBY
      end
    end

    context "when consecutive assignments without blank line before non-assignment" do
      let(:offense_code) do
        <<~RUBY
          loop do
            user = find_user
            account = user.account
            process(user, account)
            ^^^^^^^^^^^^^^^^^^^^^^ Add a blank line after variable assignment.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          loop do
            user = find_user
            account = user.account

            process(user, account)
          end
        RUBY
      end

      it "registers an offense on the non-assignment line" do
        expect_offense(offense_code)
      end

      it "autocorrects by adding a blank line" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when assignment is the last statement" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          loop do
            result = process
          end
        RUBY
      end
    end
  end

  describe "in method definitions" do
    context "when assignment is followed by unrelated code without blank line" do
      let(:offense_code) do
        <<~RUBY
          def process
            result = calculate
            log_completion
            ^^^^^^^^^^^^^^ Add a blank line after variable assignment.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def process
            result = calculate

            log_completion
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by adding a blank line" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when assignment is followed by unrelated return without blank line" do
      let(:offense_code) do
        <<~RUBY
          def process
            result = calculate
            other_value
            ^^^^^^^^^^^ Add a blank line after variable assignment.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def process
            result = calculate

            other_value
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by adding a blank line" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end
  end

  describe "compound assignment operators" do
    context "when ||= is followed by unrelated code" do
      let(:offense_code) do
        <<~RUBY
          def memoized
            @value ||= compute
            log_access
            ^^^^^^^^^^ Add a blank line after variable assignment.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def memoized
            @value ||= compute

            log_access
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by adding a blank line" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when += is followed by unrelated code" do
      let(:offense_code) do
        <<~RUBY
          def increment
            count += 1
            notify_observers
            ^^^^^^^^^^^^^^^^ Add a blank line after variable assignment.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def increment
            count += 1

            notify_observers
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by adding a blank line" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end

    context "when += is followed by the same variable" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def increment
            count += 1
            count
          end
        RUBY
      end
    end
  end

  describe "class method definitions" do
    context "when assignment is followed by unrelated code" do
      let(:offense_code) do
        <<~RUBY
          def self.process
            result = calculate
            log_completion
            ^^^^^^^^^^^^^^ Add a blank line after variable assignment.
          end
        RUBY
      end

      let(:corrected_code) do
        <<~RUBY
          def self.process
            result = calculate

            log_completion
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code)
      end

      it "autocorrects by adding a blank line" do
        expect_offense(offense_code)

        expect_correction(corrected_code)
      end
    end
  end

  describe "edge cases" do
    context "when body has only one statement" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def process
            result = calculate
          end
        RUBY
      end
    end

    context "when no assignments exist" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def process
            calculate
            save
          end
        RUBY
      end
    end

    context "when block has no body" do
      it "does not register an offense for inline block" do
        expect_no_offenses(<<~RUBY)
          items.each { |item| process(item) }
        RUBY
      end

      it "does not register an offense for empty block" do
        expect_no_offenses(<<~RUBY)
          items.each do |item|
          end
        RUBY
      end
    end

    context "when method has no body" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def process
          end
        RUBY
      end
    end
  end
end
