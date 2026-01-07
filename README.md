# RuboCop::Vibe [![Build Status](https://github.com/tristandunn/rubocop-vibe/actions/workflows/ci.yml/badge.svg)](https://github.com/tristandunn/rubocop-vibe/actions/workflows/ci.yml)

A set of custom cops to use on AI-generated code.

I have a preferred style of Ruby whether I'm vibe coding or not, so this library
is meant to handle the easy formatting scenarios that I often find myself
manually correcting. I plan to add to this over time anytime AI-generated code
isn't to my preference.

And if it's not obvious, I **am** _almost_ vibe coding this library, since I do
skim the changes, review the test scenarios, and test it on personal projects.

## Installation

Just install the `rubocop-vibe` library.

```sh
$ gem install rubocop-vibe
```

Or, if you use Bundler, put this in your `Gemfile`.

```ruby
gem "rubocop-vibe", require: false
```

## Usage

You need to tell RuboCop to load the extension:

### RuboCop configuration file

Put this into your `.rubocop.yml`.

```yaml
plugins: rubocop-vibe
```

Alternatively, use the following array notation when specifying multiple
extensions.

```yaml
plugins:
  - rubocop-other-extension
  - rubocop-vibe
```

Now you can run `rubocop` and it will automatically load the cops together with
the standard cops.

## The Cops

All cops are located under [`lib/rubocop/cop/vibe`](lib/rubocop/cop/vibe) and
contain examples/documentation.

In your `.rubocop.yml`, you may treat the cops just like any other cop. For
example:

```yaml
Vibe/ClassOrganization:
  Exclude:
    - lib/example.rb
```

## License

rubocop-vibe uses the MIT license. See LICENSE for more details.
