#!/bin/bash
# Detect the best available Python installer for graphifyy

HAS_UV=false
HAS_PIPX=false
HAS_PIP=false

if command -v uv >/dev/null 2>&1; then
    HAS_UV=true
fi

if command -v pipx >/dev/null 2>&1; then
    HAS_PIPX=true
fi

if python3 -m pip --version >/dev/null 2>&1 || pip3 --version >/dev/null 2>&1; then
    HAS_PIP=true
fi

echo "Installer availability:"
echo "  uv: $HAS_UV"
echo "  pipx: $HAS_PIPX"
echo "  pip: $HAS_PIP"
echo ""

if [ "$HAS_UV" = true ]; then
    echo "RECOMMENDATION: Use uv (fastest, modern)"
    echo "Command: uv tool install --upgrade graphifyy"
elif [ "$HAS_PIPX" = true ]; then
    echo "RECOMMENDATION: Use pipx (isolated)"
    echo "Command: pipx install graphifyy --force"
elif [ "$HAS_PIP" = true ]; then
    echo "RECOMMENDATION: Use pip (fallback)"
    echo "Command: python3 -m pip install graphifyy --upgrade"
else
    echo "RECOMMENDATION: No supported installer found."
    exit 1
fi
