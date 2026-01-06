# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::NoAssignsAttributeTesting, :config do
  context "when in a controller spec" do
    context "when testing model attributes from assigns" do
      let(:offense_code) do
        <<~RUBY
          RSpec.describe UsersController do
            it "returns the user email" do
              get :show, params: { id: 1 }
              expect(assigns(:user).email).to eq('test@example.com')
                                    ^^^^^ Do not test attributes or associations from assigns. Only test the assignment itself: `expect(assigns(:var)).to eq(object)`
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/controllers/users_controller_spec.rb")
      end
    end

    context "when testing associations from assigns" do
      let(:offense_code) do
        <<~RUBY
          RSpec.describe PostsController do
            it "returns the post count" do
              get :index
              expect(assigns(:user).posts.count).to eq(5)
                                    ^^^^^ Do not test attributes or associations from assigns. Only test the assignment itself: `expect(assigns(:var)).to eq(object)`
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/controllers/posts_controller_spec.rb")
      end
    end

    context "when testing nested associations from assigns" do
      let(:offense_code) do
        <<~RUBY
          RSpec.describe CommentsController do
            it "checks the author name" do
              get :show, params: { id: 1 }
              expect(assigns(:comment).author.name).to eq('John')
                                       ^^^^^^ Do not test attributes or associations from assigns. Only test the assignment itself: `expect(assigns(:var)).to eq(object)`
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/controllers/comments_controller_spec.rb")
      end
    end

    context "when testing collection methods on assigns" do
      let(:offense_code) do
        <<~RUBY
          RSpec.describe UsersController do
            it "checks the size" do
              get :index
              expect(assigns(:users).size).to eq(3)
                                     ^^^^ Do not test attributes or associations from assigns. Only test the assignment itself: `expect(assigns(:var)).to eq(object)`
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(offense_code, "spec/controllers/users_controller_spec.rb")
      end
    end

    context "when only testing the assignment itself" do
      let(:valid_code) do
        <<~RUBY
          RSpec.describe UsersController do
            it "assigns the user" do
              user = create(:user)
              get :show, params: { id: user.id }
              expect(assigns(:user)).to eq(user)
            end
          end
        RUBY
      end

      it "does not register an offense" do
        expect_no_offenses(valid_code, "spec/controllers/users_controller_spec.rb")
      end
    end

    context "when testing assignment with be matcher" do
      let(:valid_code) do
        <<~RUBY
          RSpec.describe UsersController do
            it "assigns a new user" do
              get :new
              expect(assigns(:user)).to be_a_new(User)
            end
          end
        RUBY
      end

      it "does not register an offense" do
        expect_no_offenses(valid_code, "spec/controllers/users_controller_spec.rb")
      end
    end

    context "when checking if assigns is nil" do
      let(:valid_code) do
        <<~RUBY
          RSpec.describe UsersController do
            it "does not assign user" do
              get :index
              expect(assigns(:user)).to be_nil
            end
          end
        RUBY
      end

      it "does not register an offense" do
        expect_no_offenses(valid_code, "spec/controllers/users_controller_spec.rb")
      end
    end

    context "when using assigns in subject" do
      let(:valid_code) do
        <<~RUBY
          RSpec.describe UsersController do
            subject { assigns(:user) }

            it { is_expected.to eq(user) }
          end
        RUBY
      end

      it "does not register an offense" do
        expect_no_offenses(valid_code, "spec/controllers/users_controller_spec.rb")
      end
    end
  end

  context "when not in a controller spec" do
    context "when in a model spec" do
      let(:code_with_assigns) do
        <<~RUBY
          RSpec.describe User do
            it "has an email" do
              expect(assigns(:user).email).to eq('test@example.com')
            end
          end
        RUBY
      end

      it "does not register an offense" do
        expect_no_offenses(code_with_assigns, "spec/models/user_spec.rb")
      end
    end

    context "when in a request spec" do
      let(:code_with_assigns) do
        <<~RUBY
          RSpec.describe "Users" do
            it "returns user data" do
              expect(assigns(:user).email).to eq('test@example.com')
            end
          end
        RUBY
      end

      it "does not register an offense" do
        expect_no_offenses(code_with_assigns, "spec/requests/users_spec.rb")
      end
    end

    context "when in a regular Ruby file" do
      let(:code_with_assigns) do
        <<~RUBY
          class SomeClass
            def something
              assigns(:user).email
            end
          end
        RUBY
      end

      it "does not register an offense" do
        expect_no_offenses(code_with_assigns, "lib/some_class.rb")
      end
    end
  end

  context "when assigns is used in other contexts in controller specs" do
    context "when assigns is in a let block" do
      let(:valid_code) do
        <<~RUBY
          RSpec.describe UsersController do
            let(:assigned_user) { assigns(:user) }

            it "assigns the user" do
              get :show, params: { id: 1 }
              expect(assigned_user).to eq(user)
            end
          end
        RUBY
      end

      it "does not register an offense" do
        expect_no_offenses(valid_code, "spec/controllers/users_controller_spec.rb")
      end
    end

    context "when assigns is stored in a variable" do
      let(:valid_code) do
        <<~RUBY
          RSpec.describe UsersController do
            it "assigns the user" do
              get :show, params: { id: 1 }
              assigned_user = assigns(:user)
              expect(assigned_user).to eq(user)
            end
          end
        RUBY
      end

      it "does not register an offense" do
        expect_no_offenses(valid_code, "spec/controllers/users_controller_spec.rb")
      end
    end
  end
end
