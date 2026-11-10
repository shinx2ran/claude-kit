# Model routing kit: setup and tuning

Fable runs the session and makes the decisions. Haiku and Sonnet agents do the searching, testing, research and routine edits, and send back short reports.

```
                    You
                     │
           ┌─────────▼──────────┐
           │  Main session      │  understands, plans, decides,
           │  Fable             │  does the keep list, signs off
           └─────────┬──────────┘
     brief ┌─────────┼──────────┬────────────┬────────────┐
           ▼         ▼          ▼            ▼            ▼
       Explore   test-runner  docs-        worker      reviewer
       Haiku     Haiku        researcher   Sonnet      Sonnet
       finds     runs tests   Sonnet       makes the   checks the
       code      & builds     reads docs   change      change
           └─────────┴──────────┴────────────┴────────────┘
                       short reports back to Fable
```

## What's in the kit

| File | What it does |
|---|---|
| `claude-config/rules/model-routing.md` | The routing rules the main session follows. Replaces the v1 `CLAUDE.md`. |
| `claude-config/agents/explore.md` | Haiku. Finds code. Replaces the built-in Explore, which runs on Opus when your main model is Fable. |
| `claude-config/agents/test-runner.md` | Haiku. Runs tests and builds, and reports only the failures. |
| `claude-config/agents/docs-researcher.md` | Sonnet. Looks up library and API docs on the web. |
| `claude-config/agents/repeater.md` | Haiku at low effort. Repeats one defined change across many files. |
| `claude-config/agents/worker.md` | Sonnet. Makes clearly specified changes. |
| `claude-config/agents/reviewer.md` | Sonnet. Checks a finished change with fresh eyes. |
| `claude-config/agents/db-agent.md` | Opus. All Supabase work, through its own connection. See "Supabase setup" below. |
| `claude-config/settings.merge.json` | Four settings to merge into your `settings.json`. |
| `project-template/CLAUDE.md` | Facts about one project. Fill in a copy for each app. |

The routing rules live in `rules/` instead of `CLAUDE.md`, so installing them never overwrites a `CLAUDE.md` you already have.

## Step 0: check what Fable costs you

In Claude Code, run `/model` and look at the Fable row. If it says **Requires usage credits**, your Fable usage is billed to usage credits (paid extra usage) instead of your plan's included limits. In that case the main session's own turns become the biggest cost, and Mode B (at the end of this file) is worth testing first.

## Install on iPad (cloud sessions)

On iPad, Claude Code runs as **cloud sessions**: the Code tab in the Claude app, or claude.ai/code in Safari. A cloud session runs on Anthropic's computers and only sees what's in a **GitHub repository**. So the kit lives inside each project's repository, not in a folder on your device.

**1. One GitHub repository per app.** Create it on github.com (Safari works), and connect GitHub when the Code tab asks.

**2. Put the kit into the repository**, with this layout:

```
your-app/
├── CLAUDE.md                  ← from project-template/, filled in
└── .claude/
    ├── settings.json          ← the contents of settings.merge.json
    ├── rules/model-routing.md
    └── agents/                ← all 7 agent files
```

The easiest way: start a cloud session on the repository and ask Claude to create these files, or let Claude (in chat) push them to the repository for you.

**3. In the session, run** `/model fable` and `/advisor off`. Cloud sessions take the value after the command; there's no picker.

### Supabase setup (for db-agent), done in the cloud environment

The cloud environment is the saved setup your sessions run in. Open it from the environment selector in the Code tab or at claude.ai/code, then choose to edit it.

1. **Network access:** change it from **Trusted** to **Custom**, keep the default domains included, and add `mcp.supabase.com`. Without this, sessions can't reach Supabase.
2. **Network secret:** under **Network secrets**, add a secret. Allowed website: `mcp.supabase.com`. Header: `Authorization`, prefix `Bearer`, value: your Supabase personal access token (Supabase dashboard → Account → Access Tokens). Anthropic's proxy adds the token to each request, so the token never sits inside the session, the repository, or any file.
3. **Project ID:** in `.claude/agents/db-agent.md`, replace `YOUR_PROJECT_REF` with your project's ID (the last part of `supabase.com/dashboard/project/<this part>`). The ID isn't a secret.

**Never put the token in an environment variable or a file.** Anyone who can use the environment can read its variables; only network secrets stay hidden.

Point db-agent at a test project first. Switch to the real store database only after the test cases pass.

**Don't also turn on the claude.ai Supabase connector in these sessions.** The connector has full access to every project and the main session would see it, which bypasses db-agent's limits.

### On a computer instead

If you later run Claude Code on a Mac or PC, copy `rules/` and `agents/` into `~/.claude/` (Windows: `C:\Users\<you>\.claude\`), merge `settings.merge.json` into `~/.claude/settings.json`, and give db-agent its token with a `headers:` line under its `url:` (`Authorization: "Bearer ${SUPABASE_ACCESS_TOKEN}"`), with the token stored as an environment variable on that computer.

## Check that it works

| Check | How | You should see |
|---|---|---|
| Rules loaded | `/context`, under Memory files | `model-routing.md` in the list |
| Agents loaded | Ask "which subagent types can you use?" | All seven agents (Explore, test-runner, docs-researcher, repeater, worker, reviewer, db-agent), listed |
| Supabase connected | Ask "list the tables in Supabase", then `/tasks` | A db-agent row on Opus, and a real table list |
| Right models | Ask "find where the price is calculated", then run `/tasks` while it runs | The Explore row shows Haiku |
| Cost | `/usage` after a few tasks | What the session used. Compare it with a similar task done before the kit. |

## What each setting does

| Setting | Why it's there |
|---|---|
| `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` | Agents without their own model line, such as general-purpose, run on Sonnet instead of Fable. |
| `CLAUDE_CODE_FORK_SUBAGENT=0` | Stops Claude from starting forks on its own. A fork is a copy of the whole conversation and runs on Fable. This also lets Claude wait for an agent's result when the next step depends on it. You can still start a fork yourself with `/subtask`. |
| `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1` | Agents can't start agents of their own. Control and cost stay with the main session. |
| `CLAUDE_CODE_GLOB_NO_IGNORE=false` | File search skips git-ignored folders such as `node_modules`, so Explore wastes less time on junk. |

**Don't set these:**

- `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`: it forces one model onto every agent and ignores each agent's own model line, which breaks the Haiku/Sonnet split.
- `CLAUDE_CODE_EFFORT_LEVEL`: it overrides the effort line in every agent file.
- Ultracode, for now: with it on, Claude plans its own multi-agent workflows. Test it separately.

## Guardrails built into the agent files

- Explore and docs-researcher have no edit or command tools. Repeater can edit files but has no command tools. Test-runner and reviewer have no edit tools, and their instructions forbid changes. They can still run commands, which go through your normal permission prompts.
- `worker` can't use connectors (MCP), so it can't touch a live database such as Supabase. It also can't start agents of its own. If a worker needs a connector, remove `mcp__*` from the `disallowedTools` line in `worker.md`.
- `db-agent` can only use the Supabase tools listed in its file, all on its own connection. It can read freely, but every change triggers your permission prompt, and it must show the SQL first. Don't run it in a mode that skips permission prompts (such as bypass permissions), or that approval step disappears.
- The read-only agents stop after 20 to 30 turns, so a confused agent can't run forever. If one stops early, its report is marked partial.

## Tuning

Watch the one-line routing note at the end of each task, and `/tasks` while agents run.

| What you see | Likely cause | Try this |
|---|---|---|
| Fable re-opens files after Explore, or Explore misses things | Haiku is too weak for this code | In `explore.md`, set `effort: high`. If it's still weak, set `model: sonnet`. |
| repeater skips many items, or its random spot-checks show wrong edits | Low effort is too little for this pattern | In `repeater.md`, set `effort: medium`. If it's still wrong, send that kind of job to `worker`. |
| test-runner quotes errors that don't match the real output | Haiku misreads long logs | In `test-runner.md`, set `model: sonnet`. |
| The worker often fails or gets blocked | Briefs are too thin, or tasks too big | Ask Fable to show you the last brief. Fix the brief first; then try `effort: high` in `worker.md`. |
| The reviewer finds nothing real in 5 or more reviews | You're paying for checks you don't need | In `model-routing.md`, use the reviewer only for money and stock logic. |
| Lots of agents for tiny jobs | Startup overhead eats the savings | In `model-routing.md`, change "one or two lookups" to "up to three lookups". |
| Fable does searches itself | Rules not loaded, or ignored | Run the `/context` check. Then remind it once: "use Explore for searches". |
| `/tasks` often shows the Plan agent | Plan mode research runs on Fable | Add `"Agent(Plan)"` to `permissions.deny` in `settings.json`. |
| An agent's report is marked partial | Its turn limit is too low | Raise `maxTurns` in that agent's file. |
| Opus escalations rarely succeed, and the job ends up on Fable anyway | The Opus step adds cost without saving Fable turns | In `model-routing.md`, remove the Opus step from the escalation ladder. |
| The Opus reviewer finds nothing that your own line-by-line read didn't | It duplicates the main session's check | Use a Sonnet reviewer for money logic, or drop the reviewer for it. |
| Usage is still high overall | The main session's own turns dominate | Test Mode B. |

**Starting guesses to tune:** up to 3 agents in parallel; reviewer for 4 or more files or about 150 lines; two tries before moving a job up a level; 20 to 30 turns for the read-only agents; the effort level in each agent file.

**Optional running log:** to keep the routing notes in a file you can send for tuning, add this line to the end of `model-routing.md`: "Also append the routing line to `routing-log.md` in the project root."

## Mode B: an alternative to test

Instead of Fable running every turn, Sonnet runs the session and calls Fable as an **advisor** only at decision points: before it commits to a plan, when it's stuck, and before it declares a task done. Anthropic documents this pairing as usually cheaper than running the stronger model throughout.

1. If Step 0 showed "Requires usage credits", run `/model fable` once and accept, so Fable can be used as the advisor.
2. Run `/model sonnet`.
3. Run `/advisor fable`.

The same agents and rules apply. `model-routing.md` already tells a non-Fable main session to consult the advisor before keep-list work and before sign-off.

Things to know:

- The advisor is experimental. It needs Anthropic's own service (a Claude subscription is fine) and doesn't work if telemetry is turned off.
- Each advisor call reads the whole conversation from scratch. Use `/clear` between unrelated tasks so those calls stay small.
- Sonnet agents can also call the Fable advisor, so watch `/usage`.

To compare the two modes fairly, run the same two or three real tasks in each mode, then look at cost and how many fixes each needed.
