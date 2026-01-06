# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::DescribeBlockOrder, :config do
  describe "#on_block" do
    context "when describe blocks are in correct order" do
      it "does not register an offense for universal order" do
        expect_no_offenses(<<~RUBY, "spec/services/processor_spec.rb")
          RSpec.describe Processor do
            describe "class" do
            end

            describe ".call" do
            end

            describe "#process" do
            end
          end
        RUBY
      end

      it "does not register an offense for model order" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            describe "class" do
            end

            describe "associations" do
            end

            describe "validations" do
            end

            describe ".find_active" do
            end

            describe "#name" do
            end
          end
        RUBY
      end

      it "does not register an offense for controller order with actions" do
        expect_no_offenses(<<~RUBY, "spec/controllers/users_controller_spec.rb")
          RSpec.describe UsersController do
            describe "class" do
            end

            describe "#index" do
            end

            describe "#show" do
            end

            describe "#create" do
            end
          end
        RUBY
      end
    end

    context "when describe blocks are out of order" do
      it "registers an offense when instance method comes before class" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            describe "#name" do
            end

            describe "class" do
            ^^^^^^^^^^^^^^^^^^^ Describe blocks should be ordered: class → constants → .class_method → #instance_method.
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          RSpec.describe User do
            describe "class" do
            end

            describe "#name" do
            end
          end
        RUBY
      end

      it "registers an offense when class method comes before class" do
        expect_offense(<<~RUBY, "spec/services/processor_spec.rb")
          RSpec.describe Processor do
            describe ".call" do
            end

            describe "class" do
            ^^^^^^^^^^^^^^^^^^^ Describe blocks should be ordered: class → constants → .class_method → #instance_method.
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          RSpec.describe Processor do
            describe "class" do
            end

            describe ".call" do
            end
          end
        RUBY
      end

      it "registers an offense when validations come before associations" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            describe "validations" do
            end

            describe "associations" do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ Describe blocks should be ordered: class → constants → .class_method → #instance_method.
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          RSpec.describe User do
            describe "associations" do
            end

            describe "validations" do
            end
          end
        RUBY
      end

      it "registers an offense when instance method comes before class method" do
        expect_offense(<<~RUBY, "spec/services/processor_spec.rb")
          RSpec.describe Processor do
            describe "#process" do
            end

            describe ".call" do
            ^^^^^^^^^^^^^^^^^^^ Describe blocks should be ordered: class → constants → .class_method → #instance_method.
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          RSpec.describe Processor do
            describe ".call" do
            end

            describe "#process" do
            end
          end
        RUBY
      end

      it "registers offense when constants come after class methods" do
        expect_offense(<<~RUBY, "spec/services/processor_spec.rb")
          RSpec.describe Processor do
            describe ".call" do
            end

            describe "constants" do
            ^^^^^^^^^^^^^^^^^^^^^^^ Describe blocks should be ordered: class → constants → .class_method → #instance_method.
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          RSpec.describe Processor do
            describe "constants" do
            end

            describe ".call" do
            end
          end
        RUBY
      end
    end

    context "when model has all sections out of order" do
      let(:model_offense) do
        <<~RUBY
          RSpec.describe User do
            describe "#name" do
            end

            describe "validations" do
            ^^^^^^^^^^^^^^^^^^^^^^^^^ Describe blocks should be ordered: class → constants → .class_method → #instance_method.
            end

            describe ".find_active" do
            end

            describe "associations" do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ Describe blocks should be ordered: class → constants → .class_method → #instance_method.
            end

            describe "class" do
            ^^^^^^^^^^^^^^^^^^^ Describe blocks should be ordered: class → constants → .class_method → #instance_method.
            end
          end
        RUBY
      end

      let(:model_correction) do
        <<~RUBY
          RSpec.describe User do
            describe "class" do
            end

            describe "associations" do
            end

            describe "validations" do
            end

            describe ".find_active" do
            end

            describe "#name" do
            end
          end
        RUBY
      end

      it "registers offenses and auto-corrects to proper order" do
        expect_offense(model_offense, "spec/models/user_spec.rb")

        expect_correction(model_correction)
      end
    end

    context "when controller has actions out of order" do
      let(:controller_offense) do
        <<~RUBY
          RSpec.describe UsersController do
            describe "#destroy" do
            end

            describe "#index" do
            ^^^^^^^^^^^^^^^^^^^^ Describe blocks should be ordered: class → constants → .class_method → #instance_method.
            end

            describe "#create" do
            end
          end
        RUBY
      end

      let(:controller_correction) do
        <<~RUBY
          RSpec.describe UsersController do
            describe "#index" do
            end

            describe "#create" do
            end

            describe "#destroy" do
            end
          end
        RUBY
      end

      it "registers offenses and auto-corrects RESTful action order" do
        expect_offense(controller_offense, "spec/controllers/users_controller_spec.rb")

        expect_correction(controller_correction)
      end
    end

    context "when there is only one describe block" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            describe "#name" do
            end
          end
        RUBY
      end
    end

    context "when in a non-spec file" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "app/models/user.rb")
          class User
            describe "#name" do
            end

            describe "class" do
            end
          end
        RUBY
      end
    end

    context "when in nested describe blocks" do
      it "does not register an offense for third-level blocks" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            describe "#name" do
              describe "with special characters" do
              end

              describe "with valid input" do
              end
            end
          end
        RUBY
      end
    end

    context "when using symbols for descriptions" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            describe "#name" do
            end

            describe :class do
            ^^^^^^^^^^^^^^^^^^ Describe blocks should be ordered: class → constants → .class_method → #instance_method.
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          RSpec.describe User do
            describe :class do
            end

            describe "#name" do
            end
          end
        RUBY
      end
    end

    context "when mixed with context blocks" do
      it "only checks describe blocks" do
        expect_no_offenses(<<~RUBY, "spec/models/user_spec.rb")
          RSpec.describe User do
            describe "class" do
            end

            context "when valid" do
            end

            describe "#name" do
            end
          end
        RUBY
      end
    end

    context "when constants are present" do
      let(:constants_offense) do
        <<~RUBY
          RSpec.describe User do
            describe ".find_active" do
            end

            describe "constants" do
            ^^^^^^^^^^^^^^^^^^^^^^^ Describe blocks should be ordered: class → constants → .class_method → #instance_method.
            end

            describe "class" do
            ^^^^^^^^^^^^^^^^^^^ Describe blocks should be ordered: class → constants → .class_method → #instance_method.
            end
          end
        RUBY
      end

      let(:constants_correction) do
        <<~RUBY
          RSpec.describe User do
            describe "class" do
            end

            describe "constants" do
            end

            describe ".find_active" do
            end
          end
        RUBY
      end

      it "places constants between class and methods" do
        expect_offense(constants_offense, "spec/models/user_spec.rb")

        expect_correction(constants_correction)
      end
    end
  end
end
