---
name: graphify-setup
description: "Use when a developer needs to install graphify and set up its MCP server for the first time, or when graphify is not working, missing, or the MCP server needs to be configured. Handles Python detection, graphify installation via uv/pipx/pip, verification of all 10 MCP tools, and writing the mcp_config.json — everything needed to get graphify fully operational."
---

# Graphify Setup & Installation

This skill handles the **complete end-to-end installation** of `graphify` (the `graphifyy` PyPI package) and configures the graphify MCP server with all 10 tools. Follow every step in order. Do not skip steps.

---

## What You Are Setting Up

**graphify** turns codebases, docs, papers, images, and video into a persistent knowledge graph with community detection, BFS/DFS querying, and shortest-path analysis.

**The MCP server** exposes 10 tools to the agent host so graphify can be used without running the full pipeline manually:

| Tool | Purpose |
|------|---------|
| `query_graph` | BFS/DFS search across the knowledge graph |
| `get_node` | Full details for a specific node by label or ID |
| `get_neighbors` | All direct neighbors of a node with edge details |
| `get_community` | All nodes in a given community by ID |
| `god_nodes` | Most connected "hub" nodes — core abstractions |
| `graph_stats` | Summary: node count, edges, communities, confidence breakdown |
| `shortest_path` | Shortest path between two concepts in the graph |
| `list_prs` | Open GitHub PRs with CI status and graph impact |
| `get_pr_impact` | Detailed graph impact for a specific PR |
| `triage_prs` | All actionable PRs ranked by review priority and merge risk |

---

## Step 1 — Check Python is Available

```bash
python3 --version 2>/dev/null || python --version 2>/dev/null
```

If neither command returns a version, **stop and tell the user:**

> ⚠️ **Python is not installed or not on PATH.**
> Install Python 3.9+ from https://www.python.org/downloads/ (or via `brew install python` on macOS, `sudo apt install python3` on Ubuntu/Debian).
> Once Python is installed, re-run this setup.

If Python is found, note the version and path. Python 3.9+ is required. If the version is older than 3.9, warn the user and suggest upgrading, but continue — graphify may still work.

---

## Step 2 — Detect the Best Installer

Run this detection to figure out which installer to use:

```bash
HAS_UV=false
HAS_PIPX=false
HAS_PIP=false

command -v uv   >/dev/null 2>&1 && HAS_UV=true
command -v pipx >/dev/null 2>&1 && HAS_PIPX=true
(python3 -m pip --version >/dev/null 2>&1 || pip3 --version >/dev/null 2>&1) && HAS_PIP=true

echo "uv=$HAS_UV pipx=$HAS_PIPX pip=$HAS_PIP"
```

**Priority order (use the first that is available):**
1. `uv` — fastest, recommended for modern setups
2. `pipx` — isolated install, second choice
3. `pip` / `pip3` — fallback

---

## Step 3 — Check if graphify is Already Installed

```bash
graphify --version 2>/dev/null || python3 -c "import graphify; print(graphify.__version__)" 2>/dev/null
```

If graphify is already installed and up to date, **print:**
```
✅ graphify vX.Y.Z is already installed.
```
Then skip to **Step 5** (verify MCP server).

If graphify is missing or the import fails, continue to Step 4.

---

## Step 4 — Install graphify

> **IMPORTANT:** The PyPI package name is `graphifyy` (with double-y). The import name is `graphify` (single-y). Do NOT confuse them when installing.

### 4a — Install via uv (preferred)

```bash
uv tool install --upgrade graphifyy
```

After install, capture the Python interpreter uv used:

```bash
UV_PYTHON=$(uv tool run --from graphifyy python -c "import sys; print(sys.executable)" 2>/dev/null)
echo "uv interpreter: $UV_PYTHON"
```

If `uv tool install` fails, fall back to 4b.

### 4b — Install via pipx (second choice)

```bash
pipx install graphifyy --force
```

If `pipx install` fails, fall back to 4c.

### 4c — Install via pip (fallback)

```bash
python3 -m pip install graphifyy --upgrade
```

If this fails with an "externally managed environment" error (common on modern Linux/macOS), try:

```bash
python3 -m pip install graphifyy --upgrade --break-system-packages
```

If all three methods fail, **stop and tell the user:**

> ❌ **Could not install graphifyy automatically.**
> Try manually:
> - `uv tool install graphifyy` (if using uv)
> - `pipx install graphifyy` (if using pipx)
> - `pip install graphifyy` (plain pip)
> See https://github.com/safishamsi/graphify for more help.

---

## Step 5 — Verify graphify Installation

Run these checks in order:

```bash
# Check 1: CLI binary on PATH
which graphify 2>/dev/null && echo "CLI: found at $(which graphify)" || echo "CLI: NOT on PATH"

# Check 2: Python import
python3 -c "import graphify; print('Import OK, version:', graphify.__version__)" 2>/dev/null \
  || echo "Import FAILED — graphify module not importable with system python3"

# Check 3: Confirm the graphify CLI works
graphify --help 2>/dev/null | head -3 || echo "CLI --help FAILED"
```

**If the CLI is missing from PATH but the import works** (common with uv or pipx), note this to the user:

> ℹ️ The `graphify` binary is not on your system PATH, but the Python module is importable.
> The MCP server will be configured to call Python directly (not the CLI binary), which is fine.
> To add graphify to PATH permanently:
> - uv: run `uv tool update-shell` and restart your terminal.
> - pipx: run `pipx ensurepath` and restart your terminal.

---

## Step 6 — Determine the Correct Python Interpreter

Confirm the **exact Python executable** that has `graphify` installed. Run:

```bash
GRAPHIFY_BIN=$(which graphify 2>/dev/null)

# Strategy 1: uv tool run (most reliable for uv installs)
PYTHON=$(uv tool run --from graphifyy python -c "import sys; print(sys.executable)" 2>/dev/null)

# Strategy 2: Read shebang from graphify binary (pipx / direct pip installs)
if [ -z "$PYTHON" ] && [ -n "$GRAPHIFY_BIN" ]; then
  SHEBANG=$(head -1 "$GRAPHIFY_BIN" | tr -d '#!')
  case "$SHEBANG" in
    *[!a-zA-Z0-9/_.@-]*) ;;
    *) "$SHEBANG" -c "import graphify" 2>/dev/null && PYTHON="$SHEBANG" ;;
  esac
fi

# Strategy 3: Fallback to system python3
if [ -z "$PYTHON" ]; then
  PYTHON=$(python3 -c "import sys; print(sys.executable)" 2>/dev/null)
fi

echo "Using Python interpreter: $PYTHON"
```

Store this value for running CLI verification and script checks.

---

## Step 7 — Configure IDE Integration (Claude Code, Cursor, Antigravity, Gemini)

Graphify integrates deeply with coding assistants to query the graph natively instead of grepping.

### 7a — Detect Installed IDEs
Run this script to detect which IDEs are installed and get setup recommendations:

```bash
# Check Claude Code
HAS_CLAUDE=false
if command -v claude >/dev/null 2>&1 || [ -d "$HOME/.claude" ]; then
    HAS_CLAUDE=true
fi

# Check Cursor
HAS_CURSOR=false
if command -v cursor >/dev/null 2>&1 || [ -d "/Applications/Cursor.app" ] || [ -d "$HOME/Library/Application Support/Cursor" ] || [ -d "$HOME/.config/Cursor" ]; then
    HAS_CURSOR=true
fi

echo "IDE detection:"
echo "  Claude Code: $HAS_CLAUDE"
echo "  Cursor: $HAS_CURSOR"
```

### 7b — Setup Claude Code Integration
Claude Code uses a custom `/graphify` skill, `CLAUDE.md` registration, and PreToolUse hook-guards in `~/.claude/settings.json`.

When registering or updating Claude Code, make sure the skill instructs the agent to:
- Run `/graphify . --code-only` followed by `graphify export html`.
- **Directory Safety Check**: Verify the current directory is a dedicated project repository and **NOT** a root/system-adjacent directory (like home `~`, Desktop, Documents, or Downloads).

To register Claude Code globally:
```bash
graphify install
```

Or repository-local:
```bash
graphify install --project
```

### 7c — Setup Cursor Integration
Cursor uses an always-on Cursor rule (`.cursor/rules/graphify.mdc`) to instruct Cursor's agent to query the local graph.

To set up the rule in your project repository:
```bash
graphify cursor install
```
This writes `.cursor/rules/graphify.mdc` with `alwaysApply: true`.

*Note*: Ensure that the generated `.cursor/rules/graphify.mdc` instructs Cursor's agent to:
1. Always run `/graphify . --code-only` and `graphify export html` when building/updating.
2. Refuse to run `/graphify` in home (`~`), Desktop, Downloads, or Documents directories to prevent indexing huge amounts of system files.

### 7d — Setup Antigravity Integration
Antigravity uses custom rules, workflows, and a local skill folder under the `.agents/` workspace directory.

To set up the integration in your repository:
```bash
graphify antigravity install
```
This writes `.agents/rules`, `.agents/workflows`, and the graphify skill files into your project.

### 7e — Setup Gemini CLI Integration
Gemini CLI uses a custom `GEMINI.md` steering block and BeforeTool hook guards.

To register Gemini CLI globally:
```bash
graphify gemini install
```

---

## Step 8 — Final Status Report

After completing all steps, print a clean summary to the user:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
graphify setup complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Package         : graphifyy vX.Y.Z
Installed via   : [uv / pipx / pip]
Python          : <path to interpreter>
IDE Integrations: [Claude Code / Cursor / Antigravity / Gemini / None]

Core Commands:
  graphify query "<q>"      — BFS/DFS traversal search across codebase graph
  graphify path "<A>" "<B>" — Shortest path between two code symbols
  graphify explain "<C>"    — Detailed explanation of a specific code node
  graphify update .         — Update the graph incrementally (AST-only)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then tell the user these **important notes:**

> **Next steps:**
> 1. **Build your first graph**: Open a project directory (ensuring it is a dedicated repo and NOT a root system folder like home, Documents, Downloads, or Desktop) and ask the agent to run `/graphify . --code-only` and then `graphify export html` on it.
>
> **Things to remember:**
> - ⚠️ **Directory Safety Guard**: **NEVER** run `/graphify` or `graphify` commands on home (`~`), desktop (`~/Desktop`), downloads (`~/Downloads`), documents (`~/Documents`), or other large system/user-wide root folders. Only run it within a dedicated code project/repository. Running it on large, non-project folders will trigger massive file crawls, leading to high CPU load and heavy token usage.
> - **Code-Only Flag**: Use the `--code-only` flag to avoid semantic extraction overhead unless doc/image indexing is explicitly needed.
> - **HTML Export**: Run `graphify export html` to generate or refresh the interactive community HTML visualization at `graphify-out/graph.html`.
> - `list_prs`, `get_pr_impact`, and `triage_prs` require a `GITHUB_TOKEN` env variable for GitHub API access.
> - The PyPI name is `graphifyy` (double-y); the import/CLI name is `graphify` (single-y) — do not mix them up.
> - If you set `GEMINI_API_KEY` or `GOOGLE_API_KEY`, semantic extraction (docs/papers/images) will use Gemini. Without it, extraction falls back to the running agent session.

See `references/troubleshooting.md` for common error scenarios and fixes.


