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

The MCP server config must point to the **exact Python executable** that has `graphify` installed. Run:

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

Store this value — you will need it to write the MCP config in Step 8.

---

## Step 7 — Check if MCP Server Module is Available

```bash
"$PYTHON" -c "import graphify.serve; print('MCP server module: OK')" 2>/dev/null \
  || echo "MCP server module NOT found — graphify.serve is missing"
```

If the serve module is missing:

> ⚠️ The `graphify.serve` module (MCP server) was not found in this installation.
> This can happen with older versions of graphifyy.
> Try upgrading: `uv tool install --upgrade graphifyy` (or `pip install --upgrade graphifyy`).

If it appears after upgrade, continue. If it still fails after upgrade, tell the user:

> ❌ The graphify MCP server module is unavailable. The graph-building CLI still works, but the 10 MCP tools will not be available to the agent until this is resolved. Check https://github.com/safishamsi/graphify for the minimum version that includes `graphify.serve`.

---

## Step 8 — Write the MCP Server Config

The global MCP config lives at:

```
~/.gemini/config/mcp_config.json
```

> ⚠️ **IMPORTANT — Read first:** The file may already exist with other MCP servers configured (e.g. `graphify-docs`). You MUST preserve all existing entries. Never overwrite the whole file blindly — merge your new `graphify` entry into the existing JSON.

### 8a — Read the existing config (if it exists)

```bash
cat ~/.gemini/config/mcp_config.json 2>/dev/null || echo '{"mcpServers":{}}'
```

### 8b — Explain and Confirm Default Graph Setup

Before writing the config, **explain what a default graph is** and **ask the user if they want to configure one**:

> 💡 **What is a Default Graph?**
> The `--graph` argument specifies a fallback `graph.json` file for the MCP server.
> 
> **Use cases:**
> - **Primary Workspace (Zero-Config)**: If set, tool calls like `query_graph`, `god_nodes`, or `shortest_path` run immediately on your main repo without needing to pass a `project_path` argument on every invocation.
> - **Dynamic Mode (Keep Empty)**: If omitted, the server runs with `args: ["-m", "graphify.serve"]`. Tools will resolve graphs dynamically per tool call via `project_path`, or fall back to `./graphify-out/graph.json` in whichever working directory the agent is running.

Ask the user explicitly:

> 📂 **Would you like to set up a default graph path for a primary project?**
> 
> 1. **Yes** — Provide the absolute path to your primary repository (e.g., `/Users/yourname/Documents/GitHub/my-project`).
> 2. **No / Skip** — Keep it clean (Dynamic mode — pass `project_path` per tool call or rely on current working directory).

If the user provides a path:
```
GRAPH_ARGS='["-m", "graphify.serve", "--graph", "<user_path>/graphify-out/graph.json"]'
```

If the user chooses No / Skip:
```
GRAPH_ARGS='["-m", "graphify.serve"]'
```

### 8c — Write the updated config

Merge the `graphify` entry into the existing `mcpServers` object. The final `graphify` block will look like:

**With default graph:**
```json
"graphify": {
  "command": "<PYTHON_EXECUTABLE>",
  "args": [
    "-m",
    "graphify.serve",
    "--graph",
    "<user_path>/graphify-out/graph.json"
  ]
}
```

**Without default graph (clean / dynamic mode):**
```json
"graphify": {
  "command": "<PYTHON_EXECUTABLE>",
  "args": [
    "-m",
    "graphify.serve"
  ]
}
```

Full example of a complete config after merging (dynamic mode):

```json
{
  "mcpServers": {
    "graphify": {
      "command": "/Users/yourname/.local/share/uv/tools/graphifyy/bin/python",
      "args": [
        "-m",
        "graphify.serve"
      ]
    },
    "graphify-docs": {
      "url": "https://graphify.com/api/mcp"
    }
  }
}
```

Write the merged JSON to `~/.gemini/config/mcp_config.json`.

---

## Step 9 — Verify All 10 MCP Tools Register

After writing the config, verify the MCP server can start and all 10 tools are available:

```bash
"$PYTHON" -c "
try:
    from graphify.serve import get_tools
    tools = get_tools()
    names = [t['name'] if isinstance(t, dict) else t.name for t in tools]
    print(f'MCP tools found: {len(names)}')
    for n in names:
        print(f'  OK: {n}')
    expected = [
        'query_graph', 'get_node', 'get_neighbors', 'get_community',
        'god_nodes', 'graph_stats', 'shortest_path',
        'list_prs', 'get_pr_impact', 'triage_prs'
    ]
    missing = [e for e in expected if e not in names]
    if missing:
        print(f'MISSING tools: {missing}')
    else:
        print('All 10 tools confirmed.')
except Exception as e:
    print(f'Could not introspect tools via get_tools(): {e}')
    print('Trying serve --help smoke test instead...')
" 2>/dev/null
```

If introspection fails (the API may differ by version), fall back to a smoke test:

```bash
"$PYTHON" -m graphify.serve --help 2>/dev/null | head -5 \
  || echo "serve module --help not available; check graphifyy version"
```

---

## Step 10 — Final Status Report

After completing all steps, print a clean summary to the user:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
graphify setup complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Package      : graphifyy vX.Y.Z
Installed via: [uv / pipx / pip]
Python       : <path to interpreter>

MCP server config : ~/.gemini/config/mcp_config.json
Default graph     : <graph path or "not set — update manually">

10 MCP Tools registered:
  query_graph    — BFS/DFS search across the knowledge graph
  get_node       — Full details for a node by label or ID
  get_neighbors  — All direct neighbors with edge details
  get_community  — All nodes in a community by ID
  god_nodes      — Most connected hub nodes (core abstractions)
  graph_stats    — Summary stats: nodes, edges, communities
  shortest_path  — Shortest path between two concepts
  list_prs       — Open GitHub PRs with graph impact
  get_pr_impact  — Detailed impact for a specific PR
  triage_prs     — All actionable PRs ranked by priority

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then tell the user these **important notes:**

> **Next steps:**
> 1. **Restart your agent/IDE** to pick up the new MCP server config. The config change is NOT hot-reloaded.
> 2. **Build your first graph:** open a project and ask the agent to run `/graphify .` on it.
> 3. **Update the default graph path** in `~/.gemini/config/mcp_config.json` whenever you switch projects, OR pass `project_path` per-call to any MCP tool at query time.
>
> **Things to remember:**
> - The MCP server only activates after the agent restarts.
> - `list_prs`, `get_pr_impact`, and `triage_prs` require a `GITHUB_TOKEN` env variable for GitHub API access.
> - `query_graph`, `get_node`, and all other graph tools require a built `graphify-out/graph.json` — run `/graphify <path>` first.
> - If you switch to a different project, either update `mcp_config.json` or pass `"project_path": "/abs/path/to/project"` as an argument to any MCP tool call.
> - The PyPI name is `graphifyy` (double-y); the import/CLI name is `graphify` (single-y) — do not mix them up.
> - If you set `GEMINI_API_KEY` or `GOOGLE_API_KEY`, semantic extraction (docs/papers/images) will use Gemini. Without it, extraction falls back to the running agent session.

See `references/troubleshooting.md` for common error scenarios and fixes.
