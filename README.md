# claude-kit

Model routing for Claude Code. Fable runs the session and decides; cheaper agents do the legwork. The kit lives **inside each app's repository** (in its `.claude` folder), so it works in cloud sessions from an iPad with nothing to configure in the browser.

| Agent | Model · effort | Job |
|---|---|---|
| Explore | Haiku · medium | Finds code |
| test-runner | Haiku · medium | Runs tests and builds, reports only failures |
| repeater | Haiku · low | Repeats one defined change across many files |
| docs-researcher | Sonnet · medium | Looks up library and API docs |
| worker | Sonnet · medium | Makes the changes (Opus when a job fails twice) |
| reviewer | Sonnet · high | Fresh-eyes check (Opus for money and stock logic) |
| general-purpose | Sonnet · medium | Fallback when none of the above fits |
| db-agent *(optional)* | Opus · high | All Supabase work, through its own connection |

## Install into an app

Open a Claude Code session on the app's repository and send this one message:

> Install my routing kit: run `git clone --depth 1 https://github.com/shinx2ran/claude-kit /tmp/claude-kit && bash /tmp/claude-kit/install.sh`, then commit the `.claude` folder and push it to the default branch.

The kit is active from the **next** session on that repository. Agents and rules are read when a session starts.

To update an app after the kit changes, send the same message again.

## What's in this repository

| Path | What it is |
|---|---|
| `kit/agents/` | The 7 agent files |
| `kit/rules/model-routing.md` | The routing rules the main session follows |
| `kit/settings.json` | One permission rule: no forks (a fork runs on the main model) |
| `kit/templates/project-CLAUDE.md` | Template the main session uses to write an app's `CLAUDE.md` |
| `install.sh` | Copies `kit/` into the current repository's `.claude/`, keeping existing settings |
| `optional/db-agent.md` | Supabase agent. Not installed by default; see `docs/REFERENCE.md` |
| `docs/REFERENCE.md` | Tuning table, test cases, Supabase setup, Mode B |

## What is enforced, and how

| Limit | Enforced by |
|---|---|
| Each agent's model and effort | The `model:` and `effort:` lines in its file |
| `general-purpose` runs on Sonnet, not the main model | A file named `general-purpose` that replaces the built-in one |
| The built-in Explore (Opus under Fable) is replaced by Haiku | A file named `Explore` |
| No forks | `Agent(fork)` in `permissions.deny` |
| Agents can't start agents | No `Agent` tool in any agent's tool list |
| Worker can't use connectors (so it can't touch a live database) | `disallowedTools: mcp__*` |

## Verified on 10 Nov 2026

Tested with Claude Code 2.1.319 in a cloud container, using headless runs:

- Agents and rules in a repository's `.claude/` folder load. ✔
- `Explore` ran on Haiku while the main session ran on Sonnet. ✔
- The `general-purpose` override ran on Sonnet while the main session ran on Haiku. ✔
- A `permissions.deny` rule in the repository's `.claude/settings.json` was applied. ✔
- The main session followed the routing rules and ended with the routing note. ✔
- **An `env` block in `settings.json` was not applied** (`CLAUDE_CODE_SUBAGENT_MODEL` had no effect from either the repository's or the home folder's settings file; it only worked as a real environment variable). The kit therefore doesn't use `env` settings.

Not tested here: forks (not available in headless runs) and the Supabase agent's connection.
