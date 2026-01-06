# Development Workflow

1. Make the changes.
2. Run the linting with auto-correct and fix any remaining issues.
   ```
   bundle exec rake rubocop:autocorrect
   ```
3. Run the tests with coverage.
   ```
   bundle exec rake spec
   ```

# Rules

- Require 100% line and branch coverage.
- Never disable a test.
- Never disable a linting rule.
- Never disable or reduce coverage thresholds.
