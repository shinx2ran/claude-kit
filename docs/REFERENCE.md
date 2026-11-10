# claude-kit reference

## Daily use

1. Start a session on an app that has the kit installed.
2. Check the model shows Fable. Send `/advisor off` once per session if you have ever set an advisor.
3. Describe the task. Each task ends with a one-line routing note, for example:
   `Routing: Explore ×2 (haiku) · worker (sonnet, 1 retry) · reviewer: 1 real issue · redone on main: none`

For database changes, use a permission mode that asks before acting. In an auto-approve mode, the approval step for database changes disappears.

## Test cases

Run these on a branch. Each checks one part of the routing rules.

| # | Ask | Should happen | Fails if |
|---|---|---|---|
| 1 | "Where is X calculated, and where is Y updated?" | One Explore (Haiku) answers both, with file and line references | Several Explore runs, or Fable re-reads whole files |
| 2 | "Change the footer text on one screen" | No agent; Fable makes the edit | Any agent starts for a one-line job |
| 3 | "Add a filter-by-brand dropdown to the stock list" | Explore, then worker (Sonnet), then test-runner; no reviewer | Fable writes the code itself |
| 4 | A change to money or stock logic | Worker at high effort, Opus reviewer, Fable shows a worked example | The example is wrong, or the review is skipped |
| 5 | "Translate all button labels on one screen to Bahasa Indonesia" | repeater (Haiku, low) | Worker or Fable does it |
| 6 | "How do I do X with our framework?" | docs-researcher answers with version and sources | Fable reads web pages itself |
| 7 | "X gives wrong totals. Find out why." | Fable investigates; a worker starts only after the cause is known | A worker starts fixing before the cause is known |

Most valuable test: on a branch, plant a small rounding bug in a price calculation and ask for a review. You know the right answer in advance, so it shows whether the review catches money errors.

## Tuning

| What you see | Likely cause | Try this |
|---|---|---|
| Fable re-opens files after Explore, or Explore misses things | Haiku is too weak for this code | In `explore.md`, set `effort: high`. If still weak, `model: sonnet`. |
| test-runner quotes errors that don't match the real output | Haiku misreads long logs | In `test-runner.md`, set `model: sonnet`. |
| repeater skips many items or makes wrong edits | Low effort is too little for this pattern | In `repeater.md`, set `effort: medium`. If still wrong, send that kind of job to `worker`. |
| The worker often fails or gets blocked | Briefs are too thin, or tasks too big | Ask Fable to show the last brief. Fix the brief first; then try `effort: high` in `worker.md`. |
| The reviewer finds nothing real in 5 or more reviews | Paying for checks you don't need | In `model-routing.md`, use the reviewer only for money and stock logic. |
| Opus escalations rarely succeed | The Opus step adds cost without saving Fable turns | Remove the Opus step from the escalation ladder. |
| Lots of agents for tiny jobs | Startup overhead eats the savings | Change "one or two lookups" to "up to three lookups". |
| Fable does searches itself on bulky jobs | Rules not loaded, or ignored | Run `/context` and look for `model-routing.md` under Memory files. |
| An agent's report is marked partial | Its turn limit is too low | Raise `maxTurns` in that agent's file. |
| Usage is still high overall | The main session's own turns dominate | Lower Fable's effort to Medium, or test Mode B. |

Starting guesses to tune: up to 3 agents in parallel; reviewer for 4 or more files or about 150 lines; two tries before moving a job up a level; 20 to 40 turns for the capped agents; the effort level in each agent file.

After changing a file in `kit/`, re-run the install message in each app.

## Supabase agent (optional)

`optional/db-agent.md` gives one Opus agent its own Supabase connection, locked to one project. It needs three things in the **cloud environment** the app's sessions use (edited at claude.ai/code, from the environment selector under the message box):

1. **Network access:** Custom, keeping the default domains, plus `mcp.supabase.com`.
2. **Network secret:** website `mcp.supabase.com`; header `Authorization`, prefix `Bearer`; value = a Supabase personal access token. Never put the token in a file or an environment variable.
3. In the app's repository, copy `optional/db-agent.md` to `.claude/agents/db-agent.md` and replace `YOUR_PROJECT_REF` with the project's ID.

Point it at a test project first. Don't also turn on the claude.ai Supabase connector in those sessions; it has full access to every project and bypasses db-agent's limits. This agent's connection has not been tested yet.

## Mode B: an alternative to test

Sonnet runs the session and calls Fable as an advisor only at decision points. Anthropic documents this pairing as usually cheaper than running the stronger model throughout.

1. `/model sonnet`
2. `/advisor fable`

The same agents and rules apply; `model-routing.md` tells a non-Fable main session to consult the advisor before keep-list work and before sign-off. The advisor is experimental, and each call reads the whole conversation, so use `/clear` between unrelated tasks. To compare fairly, run the same two or three real tasks in each mode.
