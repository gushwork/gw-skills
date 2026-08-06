#!/bin/bash
# Detect Python, installers, existing graphify installation, and IDE integrations (Claude Code, Cursor)

echo "============================================="
echo " Graphify Environment & IDE Detector"
echo "============================================="
echo ""

# Directory safety guard check
CURRENT_DIR=$(pwd)
UNSAFE_PATHS=("$HOME" "$HOME/Desktop" "$HOME/Downloads" "$HOME/Documents" "/Users" "/tmp" "/" "/var" "/etc")
IS_UNSAFE=false

for unsafe_path in "${UNSAFE_PATHS[@]}"; do
    ABS_UNSAFE=$(cd "$unsafe_path" 2>/dev/null && pwd)
    if [ "$CURRENT_DIR" = "$ABS_UNSAFE" ]; then
        IS_UNSAFE=true
        break
    fi
done

if [ "$IS_UNSAFE" = true ]; then
    echo "⚠️  WARNING: Unsafe Directory Detected!"
    echo "  You are currently in: $CURRENT_DIR"
    echo "  This appears to be a root, home, system, or desktop directory."
    echo "  Running graphify here is unsafe as it will crawl all files, causing heavy CPU and token load."
    echo "  Please run this only in a dedicated code project/repository directory."
    echo ""
fi

# 1. Check Python
PYTHON_VERSION=$(python3 --version 2>/dev/null || python --version 2>/dev/null)
if [ -z "$PYTHON_VERSION" ]; then
    echo "❌ Python: NOT FOUND (Python 3.9+ is required)"
else
    echo "✅ Python: Found ($PYTHON_VERSION)"
fi

# 2. Check Installers
HAS_UV=false
HAS_PIPX=false
HAS_PIP=false

command -v uv >/dev/null 2>&1 && HAS_UV=true
command -v pipx >/dev/null 2>&1 && HAS_PIPX=true
(python3 -m pip --version >/dev/null 2>&1 || pip3 --version >/dev/null 2>&1) && HAS_PIP=true

echo "Installer availability:"
echo "  uv: $HAS_UV"
echo "  pipx: $HAS_PIPX"
echo "  pip: $HAS_PIP"
echo ""

# 3. Check existing graphify CLI
HAS_GRAPHIFY=false
GRAPHIFY_VER=$(graphify --version 2>/dev/null || python3 -c "import graphify; print(graphify.__version__)" 2>/dev/null)
if [ -n "$GRAPHIFY_VER" ]; then
    HAS_GRAPHIFY=true
    echo "✅ Graphify: Installed ($GRAPHIFY_VER)"
else
    echo "⚠️ Graphify: NOT installed"
fi
echo ""

# 4. Check IDEs
HAS_CLAUDE=false
if command -v claude >/dev/null 2>&1 || [ -d "$HOME/.claude" ]; then
    HAS_CLAUDE=true
fi

HAS_CURSOR=false
if command -v cursor >/dev/null 2>&1 || [ -d "/Applications/Cursor.app" ] || [ -d "$HOME/Library/Application Support/Cursor" ] || [ -d "$HOME/.config/Cursor" ]; then
    HAS_CURSOR=true
fi

echo "IDE Detections:"
if [ "$HAS_CLAUDE" = true ]; then
    echo "  ✅ Claude Code: Detected"
else
    echo "  ❌ Claude Code: Not found"
fi

if [ "$HAS_CURSOR" = true ]; then
    echo "  ✅ Cursor: Detected"
else
    echo "  ❌ Cursor: Not found"
fi
echo ""

# 5. Recommendations and setup commands
echo "============================================="
echo " Recommendations & Setup"
echo "============================================="

if [ "$HAS_GRAPHIFY" = false ]; then
    echo "1. First, install graphifyy using your preferred installer:"
    if [ "$HAS_UV" = true ]; then
        echo "   👉 Run: uv tool install --upgrade graphifyy"
    elif [ "$HAS_PIPX" = true ]; then
        echo "   👉 Run: pipx install graphifyy --force"
    elif [ "$HAS_PIP" = true ]; then
        echo "   👉 Run: python3 -m pip install graphifyy --upgrade --break-system-packages"
    else
        echo "   ❌ No supported installer found. Please install uv, pipx, or pip first."
    fi
    echo ""
fi

# Claude Code Setup Suggestions
if [ "$HAS_CLAUDE" = true ]; then
    echo "Claude Code Setup:"
    echo "  To register the /graphify skill and configure PreToolUse hooks for Claude Code:"
    echo "  👉 Run (Global):  graphify install"
    echo "  👉 Run (Project): graphify install --project"
    echo ""
    echo "  👉 Build graph:   graphify . --code-only"
    echo "  👉 Export HTML:   graphify export html"
    echo ""
fi

# Cursor Setup Suggestions
if [ "$HAS_CURSOR" = true ]; then
    echo "Cursor Setup:"
    echo "  To set up always-on Cursor rules in your repository (.cursor/rules/graphify.mdc):"
    echo "  👉 Run:           graphify cursor install"
    echo ""
    echo "  👉 Build graph:   graphify . --code-only"
    echo "  👉 Export HTML:   graphify export html"
    echo ""
fi

# Antigravity Setup Suggestions (Google Antigravity)
echo "Antigravity Setup:"
echo "  To register custom rules, workflows, and skills locally in your workspace:"
echo "  👉 Run:           graphify antigravity install"
echo ""
echo "  👉 Build graph:   graphify . --code-only"
echo "  👉 Export HTML:   graphify export html"
echo ""

# Gemini Setup Suggestions (Gemini CLI)
echo "Gemini Setup:"
echo "  To register steering rules and BeforeTool hook guards globally for the Gemini CLI:"
echo "  👉 Run:           graphify gemini install"
echo ""
echo "  👉 Build graph:   graphify . --code-only"
echo "  👉 Export HTML:   graphify export html"
echo ""

if [ "$HAS_CLAUDE" = false ] && [ "$HAS_CURSOR" = false ]; then
    echo "No supported IDEs (Claude Code, Cursor) were detected."
    echo "Graphify supports 17 coding assistants. Refer to https://graphify.com/integrations for other setups."
fi

