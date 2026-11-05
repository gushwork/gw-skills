# Troubleshooting

Start with the run itself:

```bash
gh run list --workflow claude-pr-review.yml -L 5
gh run view <run-id> --log | grep -iE "error|warn|skip" | head -40
```

| Symptom | Cause | Fix |
| --- | --- | --- |
| Run ends in `startup_failure`, no jobs | The caller job has no `permissions:` block, or grants less than the called workflow needs. The org default is `read`. | Copy the `permissions:` block from [caller-workflows.md](caller-workflows.md) exactly. |
| Run succeeds in seconds, nothing posted; log says the workflow file differs from the default branch | claude-code-action only runs workflow files that match the default branch. The PR changes the caller file, or its merge ref is stale. | Expected on the PR that adds or edits the callers: review it by hand. On other PRs, merge the default branch into the PR branch to refresh the merge ref. |
| No review on a PR | The PR is a draft. | Mark it ready for review; `ready_for_review` starts a run. |
| `@claude` does nothing | The comment came from a bot and `allowed_bots` is unset, or the text does not contain `@claude`, or the event type is not in `on:`. | Set `allowed_bots: "*"` if bots should trigger it; check the `on:` triggers and `if:` match the reference. |
| `@claude` run fails parsing arguments, or the instructions are cut off | `instructions` contains `"`, `$` or a line starting with `#`. | Rewrite with single quotes or backticks; remove `$` and leading `#`. |
| A comment or reply appears under a person's name | It did not come from these workflows. A Claude Code session (desktop, web or CLI, often on a `claude/*` branch) replied using that person's GitHub login. | Turn off PR replies in that Claude Code session. These workflows always post as `claude`. |
| Commits from `@claude` show `github-actions` | An old caller or a copied workflow without `bot_id`. | Use the shared `claude.yml`; it sets `bot_name: claude[bot]` and `bot_id: 209825114`. |
| `Resource not accessible by integration` | The Claude GitHub App is not installed on the repo, or lacks access. | An org owner adds the repo to the Claude app installation. |
| `CLAUDE_CODE_OAUTH_TOKEN` empty / auth error | The org secret is not shared with this repo, or the caller does not pass it. | Pass it explicitly under `secrets:`; ask an org owner to give the repo access to the secret. |
| Summary missing but inline comments posted | The run hit `max_turns` before the summary step. | Raise `max_turns` (PR review default 100) for large PRs, or split the PR. |
| Reviewer guide in the middle of the description | Old marker block from a previous version. | The next push moves it to the bottom. Keep the markers as the last lines of the PR template. |
| Same finding posted again on every push | The earlier summary comment was deleted, so round detection lost its `<!-- claude-review-summary head=... -->` marker. | Do not delete Claude's summary comments; hide them as outdated instead. |
| Duplicate reviews | Two Claude review workflows in the repo (an old direct `anthropics/claude-code-action` job plus the caller). | Delete the old workflow. |
| Required check stuck on "Expected" | The check name in the ruleset does not match. | Use `review / claude-review` and `security-review / security-review` (caller job id / called job name). Keep the caller job ids unchanged. |
| Security review too noisy | Generic categories do not fit the repo. | Add rules to `.github/security-review/false-positive-instructions.md`. |
| Security review misses repo-specific risks | Nothing tells it about them. | Add categories to `.github/security-review/scan-instructions.md`; they override the generic exclusions. |

If the shared workflow itself is wrong (prompt, permissions, tools), fix it in
gushwork/github-config with its own PR. Every merge there applies to all repos on `@main`.
To hold one repo back while that is fixed, pin it to the last good tag (`gh release list -R gushwork/github-config`).
