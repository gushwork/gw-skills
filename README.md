# gw-skills

A repository of custom agentic skills for Gushwork development workflows.

## Directory Structure

Custom skills are organized under the `skills/` directory:

```
gw-skills/
├── README.md
└── skills/
    └── graphify-setup/
        ├── SKILL.md
        ├── references/
        │   └── troubleshooting.md
        └── scripts/
            └── detect_installer.sh
```

## Available Skills

### [graphify-setup](file:///skills/graphify-setup/SKILL.md)
Use when a developer needs to install `graphify` and set up its MCP server for the first time, or when `graphify` is not working, missing, or the MCP server needs to be configured.
Handles:
- Python version detection
- Automated installation via `uv`, `pipx`, or `pip`
- MCP server configuration and merging with existing servers
- Tool introspection and validation of the 10 core graphify tools

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
```
