# gw-skills

A repository of custom agentic skills for Gushwork development workflows.

## Directory Structure

Custom skills are organized under the `skills/` directory:

```
gw-skills/
├── README.md
└── skills/
    ├── graphify-setup/
    │   ├── SKILL.md
    │   ├── references/
    │   │   └── troubleshooting.md
    │   └── scripts/
    │       └── detect_installer.sh
    ├── gushwork-pr-review-setup/
    │   ├── SKILL.md
    │   └── references/
    │       ├── caller-workflows.md
    │       ├── repo-guidance.md
    │       └── troubleshooting.md
    └── gushwork-ui-design/
        ├── SKILL.md
        └── references/
            ├── components.md
            └── design-tokens.md
```

## Available Skills

### 1. [graphify-setup](file:///skills/graphify-setup/SKILL.md)
Use when a developer needs to install `graphify` and set up integration for the first time, or when `graphify` is not working or missing.
Handles:
- Python version detection
- Automated installation via `uv`, `pipx`, or `pip`
- IDE detection and setup (`graphify claude install`, `graphify cursor install`, `graphify antigravity install`, `graphify gemini install`)
- Path safety checks & `--code-only` + `graphify export html` recommendations

### 2. [gushwork-ui-design](file:///skills/gushwork-ui-design/SKILL.md)
Use when building or restyling any Gushwork (`gushwork.ai`) web UI (dashboards, internal tools, customer/demo apps, analytics views, login/auth screens) to match the official Gushwork design language.
Covers:
- Color tokens (`primary` `#0070FF`, `neutral-100` hairline borders, `gw-*` semantic families)
- Two-font hierarchy (`VertGroteskDisplay` for headings/numbers + `Inter` for body)
- 12 non-negotiable design rules (divided cards, `shadow-s3`/`s4`, clean tables, Recharts styling)
- Copy-paste component catalog & Tailwind v4 `@theme` setup

### 3. [gushwork-pr-review-setup](file:///skills/gushwork-pr-review-setup/SKILL.md)
Use when adding Gushwork's shared Claude GitHub Actions (from `gushwork/github-config`) to a repository, or when fixing a repo where they are not posting, are skipped, or post under a person's name.
Covers:
- Org prerequisite checks (Claude GitHub App, `CLAUDE_CODE_OAUTH_TOKEN` secret)
- Caller workflows for the Claude PR review + reviewer guide, the security review, `@claude` mentions and PR title validation
- Repo guidance: `REVIEW.md`, security scan instructions, `@claude` instructions and allowed tools per stack, PR template
- Post-merge verification, required checks, and troubleshooting

## How to Install/Use Custom Skills

To load these skills into your agent context, copy or symlink the directories from this repository to either your **Global Customizations Root** or your **Workspace Customizations Root**:

### 1. Global Installation (Recommended)
Place the skill folders inside:
```
~/.gemini/config/skills/
```

For example:
```bash
cp -R skills/graphify-setup ~/.gemini/config/skills/
cp -R skills/gushwork-ui-design ~/.gemini/config/skills/
cp -R skills/gushwork-pr-review-setup ~/.gemini/config/skills/
```

### 2. Workspace-Specific Installation
Place the skill folders under a `.agents` folder at the root of your project:
```
<workspace-root>/.agents/skills/
```

For example:
```bash
mkdir -p <workspace-root>/.agents/skills
cp -R skills/graphify-setup <workspace-root>/.agents/skills/
cp -R skills/gushwork-ui-design <workspace-root>/.agents/skills/
cp -R skills/gushwork-pr-review-setup <workspace-root>/.agents/skills/
```
