---
name: gushwork-pr-review-setup
description: >-
  Use when adding Gushwork's shared Claude GitHub Actions to a repository, or when
  checking or fixing a repo that already has them. Sets up the three reusable
  workflows from gushwork/github-config (Claude PR review with reviewer guide,
  Claude security review, and @claude mentions), plus the optional PR title check,
  PR template, REVIEW.md, security scan instructions and required checks. Trigger on
  "set up Claude review", "add the claude actions", "add @claude to this repo",
  "enable security review", "onboard repo to github-config", or when a repo's Claude
  review is not posting, is skipped, or posts under a person's name.
---

# Gushwork PR review setup

This skill adds Gushwork's shared Claude workflows to one repository. All logic lives in
[gushwork/github-config](https://github.com/gushwork/github-config). The target repo only
gets small caller files that point at it, plus repo-specific guidance. Follow the steps in
order. Do not skip the checks in Step 1.

---

## What you are setting up

| Caller file in the target repo | Calls (in github-config) | What it does |
| --- | --- | --- |
| `.github/workflows/claude-pr-review.yml` | `claude-pr-review.yml` | Reviews every non-draft PR push. Posts verified findings as inline comments (**Important**, **Nit**, **Pre-existing**), one summary comment per run, and writes a **reviewer guide** at the bottom of the PR description. Later pushes review only the new commits. |
| `.github/workflows/claude-security-review.yml` | `claude-security-review.yml` | Security-only review. Inline `**[HIGH]**` / `**[MEDIUM]**` findings and one `Security review:` summary, with a "Worth knowing (not vulnerabilities)" section for cost, budget, race, prompt-injection, customer-data, audit-log and dependency issues. |
| `.github/workflows/claude.yml` | `claude.yml` | Answers `@claude` in issues, PR comments and reviews. Can push commits to the PR branch. |
| `.github/workflows/valid-pr.yml` (optional) | `valid-pr.yml` | Fails PRs whose title is not a Conventional Commit (`feat:`, `fix(scope):`, `refactor!:` ...). |

Repo-specific files the workflows read if they exist:

| File | Read by | Purpose |
| --- | --- | --- |
| `REVIEW.md` | PR review | What counts as a real problem in this repo, what to ignore. Overrides the generic review advice. |
| `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, `.cursor/rules/`, `.github/instructions/`, `.github/copilot-instructions.md` | all three | Build, test and code conventions. |
| `.github/security-review/scan-instructions.md` | security review | Extra security categories. They override the generic exclusions. |
| `.github/security-review/false-positive-instructions.md` | security review | Extra rules for dropping findings. |
| `.github/pull_request_template.md` | humans + PR review | Sections for What changed, Testing, Risk, How to revert, and the reviewer-guide markers. |

### Facts that shape every caller file

- **Only one secret.** Every Claude workflow takes only `CLAUDE_CODE_OAUTH_TOKEN` (an org secret). Pass it explicitly. **Never use `secrets: inherit`**: it would hand every repository secret to a job that runs a model on untrusted PR content.
- **The caller must grant permissions.** The org default token permission is `read`. A called workflow cannot get more than its caller job grants. A missing `permissions:` block ends the run in `startup_failure`.
- **Everything posts as `claude`.** Comments, the description edit and commits come from the Claude GitHub App. Never add a personal access token.
- **Pin.** Callers use `@main`, so every merge to github-config applies at once. To freeze a repo or roll back a bad release, pin an exact tag such as `@v3.1.0` (list them with `gh release list -R gushwork/github-config`).
- **The setup PR is not reviewed by Claude.** claude-code-action skips a PR that changes its own calling workflow file (it only runs workflow files that match the default branch). That is expected: review the setup PR by hand and verify on the next PR.

---

## Step 1 — Check the repository and org prerequisites

Run from the target repo's root.

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
DEFAULT=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
echo "$REPO default=$DEFAULT"

# 1. Repo must be in the gushwork org.
case "$REPO" in gushwork/*) echo "org ok";; *) echo "STOP: not a gushwork repo";; esac

# 2. Claude GitHub App installed on this repo (expect repository_selection "all", or this repo listed).
gh api orgs/gushwork/installations -q '.installations[] | select(.app_slug=="claude") | .repository_selection'

# 3. Org secret CLAUDE_CODE_OAUTH_TOKEN visible to this repo (expect visibility "all"; or "selected" with this repo listed).
gh api orgs/gushwork/actions/secrets/CLAUDE_CODE_OAUTH_TOKEN -q .visibility

# 4. Existing workflows and guidance files.
ls .github/workflows/ 2>/dev/null
ls REVIEW.md CLAUDE.md AGENTS.md CONTRIBUTING.md .github/pull_request_template.md .github/security-review/ 2>/dev/null
```

Stop and tell the user if:
- the repo is not in `gushwork`;
- the Claude app is not installed on this repo (an org owner adds it at `https://github.com/organizations/gushwork/settings/installations`);
- the secret is not visible to this repo (an org owner changes its repository access).

The `orgs/gushwork/installations` and secret calls need org admin. If they return 403, say you could not verify and continue; the first run shows whether access works.

If the repo already has Claude workflows (for example a direct `anthropics/claude-code-action` job or an older `@v2.x` pin), replace them with the callers below instead of adding a second set. Two review workflows post duplicate comments. Before you replace an inline workflow, read its prompt: the repo-specific parts (stack, packages, security concerns, review rules) move into `REVIEW.md`, the security scan instructions and the `@claude` `instructions` in Steps 4 and 5. Note behaviour changes for the PR description (model, `allowed_bots`, the account that posts).

---

## Step 2 — Learn the repository

Read before writing anything:

1. `AGENTS.md`, `CLAUDE.md`, `README.md`, `CONTRIBUTING.md`: purpose, packages, build and test commands, conventions.
2. The package manager and stack: `package.json` (npm / bun / pnpm scripts), `pyproject.toml` / `uv.lock`, `go.mod`, `Cargo.toml`, `Dockerfile`, `infra/` (Terraform/OpenTofu/CDK).
3. The CI workflow: which commands it runs (these are what `@claude` should be allowed to run).
4. Branch flow: is there a `master` → `main` production promotion? The PR review gives promotion PRs (`main` ← `master`) a light pass automatically. Nothing to configure.
5. What breaks in production here: public APIs, SDKs, migrations, money, auth, tenant isolation, queues. This goes into `REVIEW.md` and the security scan instructions.

---

## Step 3 — Add the caller workflows

Create the branch from the remote default branch, not from a local checkout, which may be stale or diverged:

```bash
git fetch origin
git checkout -b ci/claude-actions "origin/$DEFAULT"   # or: git worktree add ../<repo>-claude -b ci/claude-actions "origin/$DEFAULT"
```

Never `git pull` into an existing clone whose local default branch has diverged from origin; use a fresh branch or worktree. Copy the caller files exactly from [references/caller-workflows.md](references/caller-workflows.md). Change only:

- the `with:` block of `claude.yml` (`instructions`, `allowed_tools`, `allowed_bots`), see Step 4;
- optionally `model` / `max_turns` on the reviews (defaults: `claude-sonnet-5-5`, 100 turns for PR review, 60 for security).

Keep exactly:
- the `on:` triggers and types;
- the `permissions:` blocks;
- the explicit `CLAUDE_CODE_OAUTH_TOKEN` secret line;
- the `@claude` `if:` condition (without it, every comment in the repo starts a run);
- the caller job ids `review` and `security-review` (the required check names depend on them).

Add `valid-pr.yml` too if the repo does not already check PR titles. It uses `pull_request_target`, takes no secret and only needs `pull-requests: read`.

---

## Step 4 — Configure `@claude` for this repo

`claude.yml` takes three repo inputs. Details and stack examples: [references/repo-guidance.md](references/repo-guidance.md#claude-inputs).

- **`instructions`**: 3-8 plain sentences appended to the system prompt: what the repo is, its packages and their directories, how to scope changes, docs and test rules. Long rules belong in `AGENTS.md`, which Claude reads anyway.
  - **No double quotes (`"`), no `$`, and no line starting with `#`.** The action parses `claude_args` like a shell line: a `"` ends the string, `$VAR` expands, and `#` lines are dropped. Use single quotes or backticks instead.
- **`allowed_tools`**: the exact commands Claude may run, in `Bash(<command>)` form, plus `Edit,Read,Write`. Use the repo's CI commands. Prefix wildcards like `Bash(npm run test:*)` allow a script family. Never allow deploy, publish, `git push` (the action pushes for Claude), database clients or cloud CLIs.
- **`allowed_bots`**: `"*"` lets bot accounts (Cursor, Linear, Seer agents) trigger `@claude`. Leave it unset (no bots) unless the user asks.

---

## Step 5 — Add the review guidance

1. **`REVIEW.md`** at the repo root. Use the template in [references/repo-guidance.md](references/repo-guidance.md#reviewmd). Keep it short and specific to this repo: numbered Important rules (what failure looks like here, with file paths), Nit rules, paths to skip. Do not copy generic advice: the shared prompt already covers logic errors, races, blast radius and missing tests.
2. **`.github/security-review/scan-instructions.md`** for repos with auth, tenants, money, external input or secrets. Template in [references/repo-guidance.md](references/repo-guidance.md#security-scan-instructions). Name concrete paths and identifiers. Categories listed there are reported as vulnerabilities even if the generic exclusions (DoS, rate limits, resource use, races, logging) would drop them.
3. **`.github/security-review/false-positive-instructions.md`**: only when the user has seen repeated false positives. Skip on first setup.

---

## Step 6 — Add the PR template

If `.github/pull_request_template.md` does not exist, copy it from github-config:

```bash
gh api repos/gushwork/github-config/contents/templates/pull_request_template.md -q .content | base64 -d > .github/pull_request_template.md
```

If it exists, keep the repo's sections and add the missing ones (Testing, Risk, How to revert), plus these markers as the **last** lines:

```markdown
<!-- reviewer-guide:start -->
<!-- Claude writes the reviewer guide here on every push. It always goes at the bottom of the description. -->
<!-- reviewer-guide:end -->
```

The markers are optional. Without them the guide is still appended at the bottom. The PR review only ever rewrites text between the markers and keeps the author's text as it is.

---

## Step 7 — Check locally and open the PR

```bash
# Lint the workflows if actionlint is installed (github-config CI uses 1.7.7); otherwise at least parse the YAML.
actionlint .github/workflows/claude*.yml .github/workflows/valid-pr.yml \
  || ruby -e 'require "yaml"; ARGV.each { |f| YAML.load_file(f); puts "yaml ok #{f}" }' .github/workflows/claude*.yml

# The @claude instructions must not contain ", $ or lines starting with #.
sed -n '/instructions: |/,$p' .github/workflows/claude.yml | tail -n +2 | grep -nE '"|\$|^\s*#' && echo "STOP: fix instructions"

# No inherited secrets, and the pin is right.
grep -n "secrets: inherit" .github/workflows/*.yml && echo "STOP: remove secrets: inherit"
grep -n "gushwork/github-config" .github/workflows/*.yml
```

Commit with a Conventional Commit title, for example `ci: add shared Claude review, security review and @claude workflows`, push, and open the PR. In the PR description say:
- which workflows were added and which files Claude reads;
- that the Claude review and security review skip this PR because it changes their caller files, so it needs a human review;
- how to revert (delete the caller files, or pin an older tag).

After pushing, check the setup PR's own runs. They prove the callers resolve and the permissions are accepted, even though Claude does not review:

```bash
gh run list --branch ci/claude-actions --json workflowName,status,conclusion
gh run view <run-id> --log | grep "claude-code-action.__run;outcome"
```

Expected: both runs `success`, and the action step `outcome=skipped`. `startup_failure` means a `permissions:` block is wrong.

Do not merge it yourself unless the user asks.

---

## Step 8 — Verify after merge

On the **next** PR (a small real change, not draft):

| Check | How | Expected |
| --- | --- | --- |
| Both review runs start | `gh run list --workflow claude-pr-review.yml -L 3` and the same for `claude-security-review.yml` | `success` |
| Author | PR comments | Summary `### Claude review (round 1): ...` and `Security review: ...` posted by `claude`, not a person or `github-actions` |
| Reviewer guide | PR description | `## Reviewer guide` block at the very bottom, author's text unchanged |
| Round 2 | push one more commit | New summary says `round 2` and reviews only the new commits; no repeated inline comments |
| `@claude` | comment `@claude what does this PR change?` | Reply from `claude` within a few minutes |

If a check fails, use [references/troubleshooting.md](references/troubleshooting.md).

---

## Step 9 — Required checks (optional, ask first)

The workflows never fail on findings, so making them required only blocks merges until the reviews have run. Check names:

- `review / claude-review`
- `security-review / security-review`
- the valid-pr check (copy the exact name from a finished run's checks list)

Add them with a repository ruleset on the default branch. Start with `enforcement: evaluate`, watch a week of PRs, then switch to `active`. Draft PRs skip the reviews, which counts as passing. A ruleset affects every contributor: confirm with the user before creating one.

---

## Rules

- Never use `secrets: inherit`, never add a PAT, never pass other secrets to these jobs.
- Never copy or edit the shared prompts in the target repo. Repo behaviour goes in `REVIEW.md`, `AGENTS.md`, the security instruction files and the `claude.yml` inputs. Changes to the shared workflows go to gushwork/github-config as their own PR.
- Never narrow a `permissions:` block below what the reference shows (runs fail) or widen it (more access for a model on untrusted input).
- One set of Claude workflows per repo. Remove older copies.
