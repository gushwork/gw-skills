# Troubleshooting Graphify Setup

If you encounter issues during installation or setup, check these common scenarios:

## 1. Externally Managed Environment (`error: externally-managed-environment`)

**Symptom:** When installing via `pip install graphifyy`, you get an error that the environment is externally managed.
**Cause:** Modern Linux distributions (Ubuntu 23.04+, Debian 12+) and macOS (Homebrew Python) prevent system-wide pip installs to avoid breaking OS packages.
**Solution:**
- **Best:** Install `uv` or `pipx` and use that (`uv tool install graphifyy` or `pipx install graphifyy`).
- **Alternative:** Use the `--break-system-packages` flag: `python3 -m pip install graphifyy --upgrade --break-system-packages`
- **Alternative:** Create a virtual environment: `python3 -m venv ~/.graphify-env && source ~/.graphify-env/bin/activate && pip install graphifyy` (Note: MCP config must point to this venv's python executable).

## 2. Command Not Found (`graphify: command not found`)

**Symptom:** After installing via `uv` or `pipx`, running `graphify` in the terminal says command not found.
**Cause:** The tool's bin directory is not on your system `$PATH`.
**Solution:**
- For `uv`: Run `uv tool update-shell` and restart your terminal.
- For `pipx`: Run `pipx ensurepath` and restart your terminal.
- **Note for Agents:** Even if the CLI is missing from PATH, the Python module may still be available. The setup script will find the correct Python interpreter to use for the MCP server, so this does not block MCP functionality.

## 3. MCP Server Module Missing

**Symptom:** `python3 -m graphify.serve` fails with `No module named graphify.serve`.
**Cause:** You have an outdated version of `graphifyy` installed. The MCP server was added in a later release.
**Solution:** Upgrade the package:
- `uv tool install --upgrade graphifyy`
- `pipx upgrade graphifyy`
- `pip install --upgrade graphifyy`

## 4. GitHub PR Tools Missing or Failing

**Symptom:** The tools `list_prs`, `get_pr_impact`, and `triage_prs` do not appear, or they fail with auth errors.
**Cause:** The GitHub tools require a `GITHUB_TOKEN` environment variable to authenticate with the GitHub API.
**Solution:**
- Generate a Personal Access Token (PAT) with `repo` read access on GitHub.
- Add `export GITHUB_TOKEN="your-token"` to your `~/.zshrc` or `~/.bashrc`.
- Restart your terminal/agent.

## 5. MCP Server Config Not Loading

**Symptom:** You wrote `mcp_config.json` but the agent doesn't see the `graphify` server or tools.
**Cause:** Agent configurations for MCP servers are loaded at startup.
**Solution:** Completely restart your agent or IDE (e.g., restart Cursor/VSCode, or stop/start the agent session). The config is not hot-reloaded.

## 6. Graph Tools Return Errors

**Symptom:** Calling `query_graph`, `get_node`, etc., fails with "Graph not found" or similar.
**Cause:** The MCP server needs a `graph.json` to query. Either the default graph path in `mcp_config.json` is wrong, or the graph hasn't been built yet.
**Solution:**
- Run `/graphify .` in your project folder to build the graph.
- Pass the explicit `"project_path": "/absolute/path/to/project"` argument in your tool call, OR update the default `--graph` path in `~/.gemini/config/mcp_config.json`.
