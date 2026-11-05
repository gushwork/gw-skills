# Caller workflows

Copy these files into the target repo's `.github/workflows/`. They match the examples in
the [github-config README](https://github.com/gushwork/github-config#readme); if the README
has changed since, check the inputs there.

Pin: `@main` follows github-config main. Replace it with an exact tag (`@v3.1.0`) to freeze.

## `.github/workflows/claude-pr-review.yml`

```yaml
# Claude code review and reviewer guide, from gushwork/github-config.
# Repo-specific review rules live in REVIEW.md (and AGENTS.md).
name: Claude PR Review
run-name: "Claude PR Review · ${{ github.actor }} · ${{ github.event.pull_request.title }}"

on:
  pull_request:
    types: [opened, synchronize, ready_for_review, reopened]

jobs:
  review:
    uses: gushwork/github-config/.github/workflows/claude-pr-review.yml@main
    secrets:
      CLAUDE_CODE_OAUTH_TOKEN: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
    permissions:
      contents: read
      pull-requests: write
      id-token: write
      actions: read
      checks: read
    # with:
    #   model: claude-opus-5-5
    #   max_turns: 120
```

Required check name: `review / claude-review`.

## `.github/workflows/claude-security-review.yml`

```yaml
# Claude security review, from gushwork/github-config. Repo-specific
# categories are in .github/security-review/scan-instructions.md.
name: Claude Security Review
run-name: "Claude Security Review · ${{ github.actor }} · ${{ github.event.pull_request.title }}"

on:
  pull_request:
    types: [opened, synchronize, ready_for_review, reopened]

jobs:
  security-review:
    uses: gushwork/github-config/.github/workflows/claude-security-review.yml@main
    secrets:
      CLAUDE_CODE_OAUTH_TOKEN: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
    permissions:
      contents: read
      pull-requests: write
      id-token: write
      actions: read
    # with:
    #   model: claude-opus-5-5
```

Required check name: `security-review / security-review`.

## `.github/workflows/claude.yml`

```yaml
# Claude responds to @claude on issues, PR comments and reviews.
# The workflow comes from gushwork/github-config; repo guidance is passed inline below.
name: Claude Code
run-name: "Claude Code · ${{ github.actor }} · ${{ github.event.issue.title || github.event.pull_request.title }}"

on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
  issues:
    types: [opened, assigned]
  pull_request_review:
    types: [submitted]

jobs:
  claude:
    if: |
      (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@claude')) ||
      (github.event_name == 'pull_request_review_comment' && contains(github.event.comment.body, '@claude')) ||
      (github.event_name == 'pull_request_review' && contains(github.event.review.body, '@claude')) ||
      (github.event_name == 'issues' && (contains(github.event.issue.body, '@claude') || contains(github.event.issue.title, '@claude')))
    uses: gushwork/github-config/.github/workflows/claude.yml@main
    secrets:
      CLAUDE_CODE_OAUTH_TOKEN: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
    permissions:
      contents: write
      pull-requests: write
      issues: write
      id-token: write
      actions: read
    with:
      # Plain sentences. No double quotes, no $, no lines starting with #.
      instructions: |
        This repo is <what it is>. Packages: <dir>/ (<purpose>), <dir>/ (<purpose>).
        Scope changes to the affected package. Update docs and tests in the same change.
      # Replaces the default list. Use the repo's CI commands.
      allowed_tools: "Bash(npm ci),Bash(npm test),Bash(npm run lint),Bash(npm run build),Edit,Read,Write"
      # allowed_bots: "*"   # let Cursor, Linear or Seer agents trigger @claude
      # model: claude-opus-5-5
      # max_turns: 150
```

Inputs and defaults:

| Input | Default | Notes |
| --- | --- | --- |
| `instructions` | `""` | Appended after the shared prompt, which already tells Claude to read CLAUDE.md, AGENTS.md, .cursor/rules/, .github/instructions/, .github/copilot-instructions.md, CONTRIBUTING.md and skills/. |
| `allowed_tools` | npm, bun and uv install/test/lint/build commands, plus `Edit,Read,Write` | Setting it replaces the default entirely. |
| `allowed_bots` | `""` (no bots) | `"*"` for all bots, or a comma-separated list of bot logins. |
| `model` | `claude-sonnet-5-5` | |
| `max_turns` | `150` | |

## `.github/workflows/valid-pr.yml` (optional)

```yaml
name: Valid PR
run-name: "Valid PR · ${{ github.actor }} · ${{ github.event.pull_request.title }}"

on:
  pull_request_target:
    types: [opened, edited, reopened]

jobs:
  pr-title:
    uses: gushwork/github-config/.github/workflows/valid-pr.yml@main
    permissions:
      pull-requests: read
```

No secret. Titles must be Conventional Commits: `type(scope)!: subject`, with types such as
`feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `ci`, `chore`, `build`. The github-config
release workflow also uses these titles to pick its version bumps.

## Real example

gushwork/gw-relay has all three callers on `@main`:

```bash
gh api repos/gushwork/gw-relay/contents/.github/workflows/claude.yml -q .content | base64 -d
```
