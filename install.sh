#!/bin/bash
# Installs claude-kit into the repository you run it from.
# Usage, from the root of an app repository:
#   git clone --depth 1 https://github.com/shinx2ran/claude-kit /tmp/claude-kit && bash /tmp/claude-kit/install.sh
# Then commit and push the .claude folder. The kit is active from the next session.
set -e
KIT="$(cd "$(dirname "$0")" && pwd)/kit"
mkdir -p .claude
cp -r "$KIT/agents" "$KIT/rules" "$KIT/templates" .claude/
if [ -f .claude/settings.json ]; then
  # Keep existing settings; add the kit's deny rules without duplicates.
  jq -s '.[0] as $a | .[1] as $b | ($a * $b)
         | .permissions.deny = ((($a.permissions.deny // []) + ($b.permissions.deny // [])) | unique)' \
     .claude/settings.json "$KIT/settings.json" > .claude/settings.json.tmp
  mv .claude/settings.json.tmp .claude/settings.json
else
  cp "$KIT/settings.json" .claude/settings.json
fi
echo "claude-kit installed into $(pwd)/.claude"
echo "Next: commit and push the .claude folder. The kit is active from the next session."
