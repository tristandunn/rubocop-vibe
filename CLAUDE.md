# Development Workflow

1. Make the changes.
2. Run the linting with auto-correct and fix any remaining issues.
   ```
   bundle exec rubocop -A
   ```
3. Run the tests.
   ```
   bundle exec rspec                         # All tests.
   bundle exec rspec spec/rubocop/vibe_spec.rb # Single test.
   ```

## Requirements

- Never disable a test.
- Never disable a linting rule.
