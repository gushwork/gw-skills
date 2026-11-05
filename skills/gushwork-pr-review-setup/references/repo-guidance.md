# Repo guidance files

The shared prompts are generic. Everything specific to a repo goes in the files below.
Write them from what you learned in Step 2 of the skill: real paths, real identifiers,
real failure modes. A rule that would apply to any repo does not belong here.

## REVIEW.md

Root of the repo. The PR review reads it first, and it overrides the generic review advice.
Err on the side of verbose. Cover the nuances of this repo: why each rule exists, the
edge cases, known gotchas, past incidents, and which paths or modules behave differently from
what a newcomer would expect. A longer, specific file gives better reviews than a short one.
Add detail from the repo's history and conventions; cut only generic advice.

```markdown
# Review rules for <Repo name>

The Claude PR review reads this file before every review (`gushwork/github-config`,
`claude-pr-review.yml`). It sits on top of `AGENTS.md`, which still applies in full. Keep
this file about review, and detailed: what counts as a real problem here, and what to ignore.

## What failure looks like here

<One or two sentences: who depends on this code and what breaks for them.> Treat these as **Important**:

1. **<Contract name>.** <What change breaks callers, with paths, e.g. `src/api/routes/`>. <What is required instead.>
2. **<Data / migrations>.** <e.g. schema changes outside `migrations/`, migrations not safe while the old version still runs.>
3. **<Money / usage / auth>.** <e.g. pricing math in `billing/`, tenant checks in `auth/`.>
4. **<Secrets and infra>.** <e.g. a new secret that `infra/` does not create before deploy.>
5. **<Docs with the change>.** <e.g. behaviour changes without updated `docs/` pages.>

## Nits

At most 5 per review. Skip pure style that the formatter, linter or type checker already enforce.

## Skip these paths

- <generated code, lockfiles, build output, snapshots, fixtures>

## Promotion and release

<How code reaches production (tags, master → main), and rules about ordering, if any.>
```

Good rules name a path and a consequence ("A change to `/v1` routes that is not backwards
compatible: released SDKs keep calling it for months"). Weak rules restate general advice
("Write clean code", "Handle errors").

Real example: `gh api repos/gushwork/gw-relay/contents/REVIEW.md -q .content | base64 -d`

## Security scan instructions

`.github/security-review/scan-instructions.md`. Its categories are added to the security
review's list, and they **override** the generic exclusions and precedents. Use that to
bring back excluded areas that matter for this repo (budgets, rate limits, races, logging
of customer data) as real vulnerabilities.

```markdown
**<Repo>-specific (<one-line description of the system>):**
- <Credential> (`<header or env name>`) written into logs, queue messages, DB rows, analytics or error bodies
- <Admin or internal routes> (`<path>`) reachable without <the required check, with file>
- Cross-tenant access: one <customer / workspace / org> reading another's <data types>
- SSRF where caller-controlled <config / URL / header> chooses the outbound host or protocol
- <Auth system>: session or sign-in bypass, <allow-list> checks
- <Encryption> misuse: weak modes, reused IVs, plaintext fallbacks

**<Repo>-specific, in scope despite the general exclusions (report as vulnerabilities):**
- Budget or spend-limit bypass, including two concurrent requests that both pass a budget check
- Rate-limit bypass for a <caller key / account>
- Cost amplification: one request that triggers many paid upstream calls, uncapped retries, or unbounded sizes sent to a paid API
- <Customer content> written outside <its intended store>, for example to logs, analytics, Sentry or error bodies
```

Only list what applies. Without this file the security review still runs with its generic
categories, and still lists cost, budget, race, prompt-injection, customer-data, audit-log
and dependency issues as notes.

Real example: `gh api repos/gushwork/gw-relay/contents/.github/security-review/scan-instructions.md -q .content | base64 -d`

## False-positive instructions

`.github/security-review/false-positive-instructions.md`. Extra rules the false-positive
filters use to drop findings. Add it only after real false positives, one rule per pattern,
with the reason:

```markdown
- `scripts/` only runs on developer machines with trusted input; do not report command injection there.
- `X-Internal-Token` is checked by the load balancer before requests reach the app.
```

## Claude inputs

The `with:` block of the `claude.yml` caller.

### `instructions`

3-8 plain sentences. What the repo is, its packages and directories, how to scope changes,
and test and docs rules. Claude also reads `AGENTS.md` / `CLAUDE.md`, so do not copy them.

Hard rule: **no `"`, no `$`, no line starting with `#`.** The action parses `claude_args` as a
shell line. Use single quotes or backticks for names.

Example (TypeScript monorepo):

```yaml
instructions: |
  You are working on Relay, an LLM gateway on Cloudflare Workers. Packages: gateway/ (relay,
  routing, admin API), consumer/ (queue consumer and Postgres migrations), ui/ (admin console),
  shared/ (config schema, pricing), sdk/ (Python and TypeScript SDKs). Keep changes inside the
  affected package and put shared logic in shared/. Keep the caller API backwards compatible.
  Update the docs pages for any behaviour change in the same commit.
```

Example (Python service):

```yaml
instructions: |
  This is the <name> API, a FastAPI service. Code is in app/, tests in tests/, Alembic
  migrations in migrations/. Use uv for everything. Add or update tests for every change.
  Never edit an applied migration; add a new one.
```

### `allowed_tools`

Setting it replaces the default list. Copy the commands CI runs. Always end with `Edit,Read,Write`.

| Stack | Example |
| --- | --- |
| npm | `"Bash(npm ci),Bash(npm test),Bash(npm run lint),Bash(npm run typecheck),Bash(npm run build),Edit,Read,Write"` |
| npm workspaces with script families | `"Bash(npm ci),Bash(npm test),Bash(npm test:*),Bash(npm run test:*),Bash(npm run typecheck:*),Bash(npm run build:*),Edit,Read,Write"` |
| pnpm | `"Bash(pnpm install --frozen-lockfile),Bash(pnpm test),Bash(pnpm lint),Bash(pnpm build),Edit,Read,Write"` |
| bun | `"Bash(bun install),Bash(bun test),Bash(bun run lint),Bash(bun run build),Edit,Read,Write"` |
| uv / Python | `"Bash(uv sync),Bash(uv run pytest),Bash(uv run pytest:*),Bash(uv run ruff check),Bash(uv run ruff format --check),Bash(uv run mypy:*),Edit,Read,Write"` |
| Go | `"Bash(go build ./...),Bash(go test ./...),Bash(go test:*),Bash(go vet ./...),Edit,Read,Write"` |

Never allow: deploy or publish commands, `git push`, `gh` write commands, database clients
(`psql`, `mysql`), cloud CLIs (`aws`, `gcloud`, `wrangler deploy`, `tofu apply`), or `curl` to
arbitrary hosts. Leave out the defaults (no `allowed_tools`) only if they match the repo.

### `allowed_bots`

Unset by default: comments from bot accounts do not trigger Claude. Set `"*"` when agents
such as Cursor, Linear or Seer should be able to ask `@claude` for help. Ask the user first.
