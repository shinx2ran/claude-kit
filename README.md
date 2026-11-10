# claude-kit

Model routing for Claude Code cloud sessions. Fable runs the session and decides; Haiku, Sonnet and Opus agents do the legwork. Set up once in the cloud environment, it applies to **every repository** you open.

| Agent | Model · effort | Job |
|---|---|---|
| Explore | Haiku · medium | Finds code |
| test-runner | Haiku · medium | Runs tests and builds, reports only failures |
| repeater | Haiku · low | Repeats one defined change across many files |
| docs-researcher | Sonnet · medium | Looks up library and API docs |
| worker | Sonnet · medium | Makes the changes (Opus when a job fails twice) |
| reviewer | Sonnet · high | Fresh-eyes check (Opus for money and stock logic) |
| db-agent | Opus · high | All Supabase work, through its own connection |

## What's in this repository

| Path | Goes to | What it is |
|---|---|---|
| `home/agents/` | `~/.claude/agents/` in each session | The 7 agents |
| `home/rules/model-routing.md` | `~/.claude/rules/` | The routing rules Fable follows |
| `home/settings.json` | merged into `~/.claude/settings.json` | The 4 model settings |
| `home/templates/project-CLAUDE.md` | `~/.claude/templates/` | Template Fable uses to write each app's `CLAUDE.md` |
| `setup-script.sh` | pasted into the cloud environment | Copies the above into every new session |
| `docs/REFERENCE.md` | — | Full reference: settings explained, guardrails, tuning table, Mode B |

## Set up (once, on iPad)

In the Claude app's **Code** tab (or claude.ai/code), open the environment selector and edit your environment:

1. **Setup script:** paste the whole of `setup-script.sh`.
2. **Save**, then start a session on any repository and check:
   - Ask: *"Which subagent types can you use?"* All 7 agents should be listed.
   - Run `/context`: `model-routing.md` should appear under Memory files.
3. In that session, type `/model fable` and `/advisor off`.

## Supabase (when you have a project)

In the same environment settings:

1. **Network access:** change **Trusted** to **Custom**, keep the default domains, and add `mcp.supabase.com`.
2. **Network secrets → Add secret:** website `mcp.supabase.com`; header `Authorization`, prefix `Bearer`; value = your Supabase personal access token (Supabase dashboard → Account → Access Tokens). Never put the token anywhere else.
3. In this repository, edit `home/agents/db-agent.md` and replace `YOUR_PROJECT_REF` with your project's ID. Then do the update step below.

Start with a test project. Switch to the real store database only after the test cases pass.

## Updating the kit

1. Change files in this repository (or ask Claude to).
2. In the environment's setup script, raise `KIT_VERSION` by 1 and save. The environment rebuilds and new sessions get the new kit.

## Per-app override

An app that needs something different (for example its own Supabase project) can keep its own copy of an agent in its repository's `.claude/agents/`. A repository's copy wins over the kit's copy.
