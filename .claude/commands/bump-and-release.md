---
allowed-tools:
  - Bash(bundle exec rake)
  - Bash(bundle exec rake build)
  - Bash(bundle update --all)
  - Edit(CHANGELOG.markdown)
  - Edit(lib/rubocop/vibe/version.rb)
---

# Bump and Release

Automate the full release process for rubocop-vibe. Execute each step in order and stop immediately if any step fails.

## 1. Pre-flight Checks

First, verify we're ready to release:

1. Check we're on the `main` branch:
   ```bash
   git branch --show-current
   ```
   If not on `main`, stop and report: "Error: Must be on main branch to release."

2. Check for a clean working directory:
   ```bash
   git status --porcelain
   ```
   If there's any output (uncommitted changes), stop and report: "Error: Working directory is not clean. Commit or stash changes first."

## 2. Version Extraction & Validation

Read `CHANGELOG.markdown` and find the unreleased version.

Look for a line matching the pattern: `## X.Y.Z — Unreleased`

- If no unreleased version is found, stop and report: "Error: No unreleased version found in CHANGELOG.markdown."
- Extract the version number (e.g., `0.2.0`) for use in subsequent steps.

## 3. Update Files

### Update CHANGELOG.markdown

Replace "Unreleased" with the current date in the format "Month Dth, Year" where D has the appropriate ordinal suffix:
- 1st, 2nd, 3rd, 4th, 5th, 6th, 7th, 8th, 9th, 10th
- 11th, 12th, 13th (special cases)
- 21st, 22nd, 23rd, 24th...
- 31st

Example: "January 8th, 2026"

### Update lib/rubocop/vibe/version.rb

Update the `VERSION` constant to match the extracted version:
```ruby
VERSION = "X.Y.Z"
```

## 4. Build & Test

Run these commands in sequence, stopping if any fail:

1. Update dependencies:
   ```bash
   bundle update --all
   ```

2. Run linting and tests (must pass with 100% coverage):
   ```bash
   bundle exec rake
   ```
   If this fails, stop and report the errors.

3. Build the gem:
   ```bash
   bundle exec rake build
   ```
   This creates `pkg/rubocop-vibe-X.Y.Z.gem`.

## 5. Git Operations

1. Stage the changed files:
   ```bash
   git add CHANGELOG.markdown lib/rubocop/vibe/version.rb
   ```

2. Commit with the release message (include Claude Code attribution):
   ```bash
   git commit -m "$(cat <<'EOF'
   Release X.Y.Z.

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude <noreply@anthropic.com>
   EOF
   )"
   ```

3. Create a version tag:
   ```bash
   git tag vX.Y.Z
   ```

## 6. Publish

Output the following commands for the user to run manually (OTP is required for RubyGems):

```bash
gem push pkg/rubocop-vibe-X.Y.Z.gem
gem push --key github --host https://rubygems.pkg.github.com/tristandunn pkg/rubocop-vibe-X.Y.Z.gem
git push origin main --tags
```

## Success

Report: "Release prepared for rubocop-vibe vX.Y.Z! Run the commands above to publish."
