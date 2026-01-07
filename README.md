# RuboCop::Vibe

A set of custom cops to use on AI generated code.

## Installation

Just install the `rubocop-vibe` library.

```sh
$ gem install rubocop-vibe
```

Or if you use bundler put this in your `Gemfile`.

```ruby
gem "rubocop-vibe", require: false
```

## Usage

You need to tell RuboCop to load the extension. There are three ways to do this:

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

All cops are located under [`lib/rubocop/cop/vibe`](lib/rubocop/cop/vibe), and
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
