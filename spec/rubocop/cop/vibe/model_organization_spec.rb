# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vibe::ModelOrganization, :config do
  describe "#on_class" do
    context "when model elements are in correct order" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            include Authenticatable

            MINIMUM_AGE = 18

            has_many :posts
            belongs_to :team

            validates :name, presence: true
            validates :email, presence: true

            before_save :normalize_email
            after_create :send_welcome_email

            scope :active, -> { where(active: true) }
            scope :admin, -> { where(role: "admin") }

            def self.find_active
              active
            end

            def admin?
              role == "admin"
            end

            protected

            def can_admin?
              admin?
            end

            private

            def normalize_email
              self.email = email.downcase
            end
          end
        RUBY
      end
    end

    context "when associations come before validations" do
      it "does not register an offense for correct order" do
        expect_no_offenses(<<~RUBY)
          class Post < ApplicationRecord
            belongs_to :user
            has_many :comments

            validates :title, presence: true
          end
        RUBY
      end
    end

    context "when instance method comes before association" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            def admin?
              role == "admin"
            end

            has_many :posts
            ^^^^^^^^^^^^^^^ Model elements should be ordered: concerns → constants → associations → validations → callbacks → scopes → class methods → instance methods → protected → private.
          end
        RUBY
      end
    end

    context "when validation comes before association" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            validates :name, presence: true

            has_many :posts
            ^^^^^^^^^^^^^^^ Model elements should be ordered: concerns → constants → associations → validations → callbacks → scopes → class methods → instance methods → protected → private.
          end
        RUBY
      end
    end

    context "when scope comes before validation" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            scope :active, -> { where(active: true) }

            validates :name, presence: true
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Model elements should be ordered: concerns → constants → associations → validations → callbacks → scopes → class methods → instance methods → protected → private.
          end
        RUBY
      end
    end

    context "when class method comes before scope" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            def self.find_active
              active
            end

            scope :active, -> { where(active: true) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Model elements should be ordered: concerns → constants → associations → validations → callbacks → scopes → class methods → instance methods → protected → private.
          end
        RUBY
      end
    end

    context "when scopes are not alphabetically sorted" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            scope :inactive, -> { where(active: false) }
            scope :active, -> { where(active: true) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Model elements should be ordered: concerns → constants → associations → validations → callbacks → scopes → class methods → instance methods → protected → private.
          end
        RUBY

        expect_correction(<<~RUBY)
          class User < ApplicationRecord
            scope :active, -> { where(active: true) }

            scope :inactive, -> { where(active: false) }
          end
        RUBY
      end
    end

    context "when class methods are not alphabetically sorted" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            def self.search(query)
              where("name LIKE ?", "%\#{query}%")
            end

            def self.find_active
            ^^^^^^^^^^^^^^^^^^^^ Model elements should be ordered: concerns → constants → associations → validations → callbacks → scopes → class methods → instance methods → protected → private.
              active
            end
          end
        RUBY
      end
    end

    context "when instance methods are not alphabetically sorted" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            def name_with_title
              "\#{title} \#{name}"
            end

            def admin?
            ^^^^^^^^^^ Model elements should be ordered: concerns → constants → associations → validations → callbacks → scopes → class methods → instance methods → protected → private.
              role == "admin"
            end
          end
        RUBY
      end
    end

    context "when not a Rails model" do
      it "does not register an offense for correct order" do
        expect_no_offenses(<<~RUBY)
          class Service
            def initialize
              @value = 1
            end

            def call
              puts "hello"
            end
          end
        RUBY
      end

      it "registers an offense when instance method comes before initialize" do
        expect_offense(<<~RUBY)
          class Service
            def call
              puts "hello"
            end

            def initialize
            ^^^^^^^^^^^^^^ Class elements should be ordered: includes → constants → initialize → class methods → instance methods → protected → private.
              @value = 1
            end
          end
        RUBY
      end

      it "enforces full ordering for regular classes" do
        expect_offense(<<~RUBY)
          class Service
            def process
              "processed"
            end

            private

            def helper
              "help"
            end

            public

            def initialize
            ^^^^^^^^^^^^^^ Class elements should be ordered: includes → constants → initialize → class methods → instance methods → protected → private.
              @value = 1
            end

            def self.create
              new
            end

            CONSTANT = 42

            include Helpers
          end
        RUBY
      end
    end

    context "when model has only one element" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            validates :name, presence: true
          end
        RUBY
      end
    end

    context "when private method comes before public method" do
      it "registers an offense and corrects with proper visibility" do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            private

            def normalize_email
              self.email = email.downcase
            end

            public

            def admin?
            ^^^^^^^^^^ Model elements should be ordered: concerns → constants → associations → validations → callbacks → scopes → class methods → instance methods → protected → private.
              role == "admin"
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          class User < ApplicationRecord
            def admin?
              role == "admin"
            end

            private

            def normalize_email
              self.email = email.downcase
            end
          end
        RUBY
      end
    end

    context "when multiple methods need reordering across visibility levels" do
      it "corrects all methods with proper visibility grouping" do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            private

            def normalize_email
              self.email = email.downcase
            end

            def send_notification
              notify!
            end

            protected

            def can_edit?
            ^^^^^^^^^^^^^ Model elements should be ordered: concerns → constants → associations → validations → callbacks → scopes → class methods → instance methods → protected → private.
              true
            end

            public

            def admin?
              role == "admin"
            end

            def active?
              status == "active"
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          class User < ApplicationRecord
            def active?
              status == "active"
            end

            def admin?
              role == "admin"
            end

            protected

            def can_edit?
              true
            end

            private

            def normalize_email
              self.email = email.downcase
            end

            def send_notification
              notify!
            end
          end
        RUBY
      end
    end

    context "when protected method comes before private method" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            protected

            def can_admin?
              admin?
            end

            private

            def normalize_email
              self.email = email.downcase
            end
          end
        RUBY
      end
    end

    context "when constant comes after association" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            has_many :posts

            MINIMUM_AGE = 18
            ^^^^^^^^^^^^^^^^ Model elements should be ordered: concerns → constants → associations → validations → callbacks → scopes → class methods → instance methods → protected → private.
          end
        RUBY
      end
    end

    context "when concern comes after constant" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            MINIMUM_AGE = 18

            include Authenticatable
            ^^^^^^^^^^^^^^^^^^^^^^^ Model elements should be ordered: concerns → constants → associations → validations → callbacks → scopes → class methods → instance methods → protected → private.
          end
        RUBY
      end
    end

    context "when callback comes before validation" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            before_save :normalize_email

            validates :email, presence: true
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Model elements should be ordered: concerns → constants → associations → validations → callbacks → scopes → class methods → instance methods → protected → private.
          end
        RUBY
      end
    end

    context "when multiple callbacks are present" do
      it "does not sort callbacks alphabetically" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            before_save :normalize_email
            after_save :log_changes
            before_create :set_defaults
          end
        RUBY
      end
    end

    context "when model has all sections" do
      it "enforces complete ordering" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            include Authenticatable
            include Trackable

            MINIMUM_AGE = 18
            MAXIMUM_NAME_LENGTH = 100

            belongs_to :team
            has_many :comments
            has_many :posts

            validates :age, numericality: true
            validates :email, presence: true
            validates :name, presence: true

            after_create :send_welcome_email
            before_save :normalize_email

            scope :active, -> { where(active: true) }
            scope :admin, -> { where(role: "admin") }

            def self.find_by_email(email)
              find_by(email: email)
            end

            def self.search(query)
              where("name LIKE ?", "%\#{query}%")
            end

            def admin?
              role == "admin"
            end

            def deactivate!
              update!(active: false)
            end

            protected

            def can_admin?
              admin?
            end

            private

            def normalize_email
              self.email = email.downcase
            end

            def send_welcome_email
              UserMailer.welcome(self).deliver_later
            end
          end
        RUBY
      end
    end

    context "when reordering elements with comments" do
      it "preserves comments with their elements" do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            # This is a public method
            def admin?
              role == "admin"
            end

            # All the posts
            has_many :posts
            ^^^^^^^^^^^^^^^ Model elements should be ordered: concerns → constants → associations → validations → callbacks → scopes → class methods → instance methods → protected → private.
          end
        RUBY

        expect_correction(<<~RUBY)
          class User < ApplicationRecord
            # All the posts
            has_many :posts

            # This is a public method
            def admin?
              role == "admin"
            end
          end
        RUBY
      end
    end

    context "when file has complex class structure" do
      it "corrects method order while preserving class structure and comments" do
        expect_offense(<<~RUBY)
          module RuboCop
            module Vibe
              class Plugin < LintRoller::Plugin
                # Return information about the plug-in.
                #
                # @return [LintRoller::About] Information about the plug-in.
                def about
                  LintRoller::About.new(
                    name:        "rubocop-vibe",
                    version:     VERSION,
                    homepage:    "https://github.com/tristandunn/rubocop-vibe",
                    description: "A set of custom cops to use on AI generated code."
                  )
                end

                # Determine if the engine is supported.
                #
                # @param [LintRoller::Context] The runner context.
                # @return [Boolean] If the engine is supported.
                def supported?(context)
                  context.engine == :rubocop
                end

                # Return the rules for the plug-in.
                #
                # @return [LintRoller::Rules] The rules for this plug-in.
                def rules(_context)
                ^^^^^^^^^^^^^^^^^^^ Class elements should be ordered: includes → constants → initialize → class methods → instance methods → protected → private.
                  LintRoller::Rules.new(
                    type:          :path,
                    config_format: :rubocop,
                    value:         Pathname.new(__dir__).join("../../../config/default.yml")
                  )
                end
              end
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          module RuboCop
            module Vibe
              class Plugin < LintRoller::Plugin
                # Return information about the plug-in.
                #
                # @return [LintRoller::About] Information about the plug-in.
                def about
                  LintRoller::About.new(
                    name:        "rubocop-vibe",
                    version:     VERSION,
                    homepage:    "https://github.com/tristandunn/rubocop-vibe",
                    description: "A set of custom cops to use on AI generated code."
                  )
                end

                # Return the rules for the plug-in.
                #
                # @return [LintRoller::Rules] The rules for this plug-in.
                def rules(_context)
                  LintRoller::Rules.new(
                    type:          :path,
                    config_format: :rubocop,
                    value:         Pathname.new(__dir__).join("../../../config/default.yml")
                  )
                end

                # Determine if the engine is supported.
                #
                # @param [LintRoller::Context] The runner context.
                # @return [Boolean] If the engine is supported.
                def supported?(context)
                  context.engine == :rubocop
                end
              end
            end
          end
        RUBY
      end
    end

    context "when class is empty" do
      it "does not register an offense for empty model" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
          end
        RUBY
      end

      it "does not register an offense for empty class" do
        expect_no_offenses(<<~RUBY)
          class Service
          end
        RUBY
      end
    end

    context "when class has no body" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord; end
        RUBY
      end
    end

    context "when parent class is a method call" do
      it "treats as regular class since parent_class has no const_name" do
        expect_offense(<<~RUBY)
          class User < base_class
            def admin?
              true
            end

            def initialize
            ^^^^^^^^^^^^^^ Class elements should be ordered: includes → constants → initialize → class methods → instance methods → protected → private.
              @value = 1
            end
          end
        RUBY
      end
    end

    context "when class body contains non-categorizable nodes" do
      it "ignores block nodes" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            has_many :posts

            around_action do
              yield
            end

            validates :name, presence: true
          end
        RUBY
      end
    end

    context "when scope has no symbol argument" do
      it "assigns empty sort key" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            scope -> { where(active: true) }
          end
        RUBY
      end

      it "does not register scope with string argument" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            scope "active", -> { where(active: true) }
            scope "admin", -> { where(role: "admin") }
          end
        RUBY
      end
    end

    context "when elements are already in correct order with no corrections needed" do
      it "does not make unnecessary corrections" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            has_many :posts

            validates :name, presence: true
          end
        RUBY
      end
    end

    context "when inheriting from namespaced ApplicationRecord" do
      it "treats as a model" do
        expect_offense(<<~RUBY)
          class User < MyEngine::ApplicationRecord
            def admin?
              true
            end

            has_many :posts
            ^^^^^^^^^^^^^^^ Model elements should be ordered: concerns → constants → associations → validations → callbacks → scopes → class methods → instance methods → protected → private.
          end
        RUBY
      end
    end

    context "when inheriting from ActiveRecord::Base" do
      it "treats as a model" do
        expect_offense(<<~RUBY)
          class User < ActiveRecord::Base
            def admin?
              true
            end

            has_many :posts
            ^^^^^^^^^^^^^^^ Model elements should be ordered: concerns → constants → associations → validations → callbacks → scopes → class methods → instance methods → protected → private.
          end
        RUBY
      end
    end

    context "when private visibility comes before protected visibility" do
      it "registers offense for private before protected" do
        expect_offense(<<~RUBY)
          class Service
            private

            def zzz_method
              "zzz"
            end

            protected

            def aaa_method
            ^^^^^^^^^^^^^^ Class elements should be ordered: includes → constants → initialize → class methods → instance methods → protected → private.
              "aaa"
            end
          end
        RUBY
      end
    end

    context "when scopes need reordering with non-symbol arguments" do
      it "autocorrects scopes with empty sort keys" do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            scope -> { where(active: true) }

            has_many :posts
            ^^^^^^^^^^^^^^^ Model elements should be ordered: concerns → constants → associations → validations → callbacks → scopes → class methods → instance methods → protected → private.
          end
        RUBY

        expect_correction(<<~RUBY)
          class User < ApplicationRecord
            has_many :posts

            scope -> { where(active: true) }
          end
        RUBY
      end

      it "does not register multiple scopes with empty sort keys" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            scope -> { where(active: true) }
            scope -> { where(admin: true) }
          end
        RUBY
      end

      it "does not register scopes with string names" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            scope "active", -> { where(active: true) }
            scope "admin", -> { where(admin: true) }
          end
        RUBY
      end

      it "does not register scopes with block syntax" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            scope do
              where(active: true)
            end

            scope do
              where(admin: true)
            end
          end
        RUBY
      end

      it "does not register scope with no arguments" do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            scope

            scope
          end
        RUBY
      end
    end
  end
end
