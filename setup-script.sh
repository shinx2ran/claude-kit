#!/bin/bash
# claude-kit loader for Claude Code cloud environments.
# Paste this whole script into: cloud environment > Edit > Setup script.
# After you update the claude-kit repository, raise KIT_VERSION by 1 and save.
# That makes the environment rebuild and pick up the new kit.
KIT_VERSION=1

KIT_DIR=/tmp/claude-kit
rm -rf "$KIT_DIR"
if git clone --depth 1 https://github.com/shinx2ran/claude-kit.git "$KIT_DIR"; then
  mkdir -p ~/.claude
  # Agents, rules and templates
  cp -r "$KIT_DIR/home/agents" "$KIT_DIR/home/rules" "$KIT_DIR/home/templates" ~/.claude/
  # Settings: merge into any existing file instead of replacing it
  if [ -f ~/.claude/settings.json ]; then
    jq -s '.[0] * .[1]' ~/.claude/settings.json "$KIT_DIR/home/settings.json" > /tmp/claude-settings.json \
      && mv /tmp/claude-settings.json ~/.claude/settings.json
  else
    cp "$KIT_DIR/home/settings.json" ~/.claude/settings.json
  fi
  echo "claude-kit v$KIT_VERSION installed"
else
  echo "claude-kit: clone failed; session starts without the kit"
fi
exit 0
