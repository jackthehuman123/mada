# Asking Claude on GitHub

Claude can answer questions and make changes for Làng Vọng straight from GitHub. You write `@claude` in an issue or a
pull request, and Claude replies there. It works on **this repo only** (`mada`): it can't see or touch anything else.

## What it can and can't do

| It can | It can't |
| --- | --- |
| Answer questions about the game, the code and the design docs | Open Roblox Studio, play the game or run the tests (`tools/factory/test.py`) |
| Draft or change clue texts, dialogue, ending cards (marked DRAFT, from `story.md` only, as `AGENTS.md` requires) | Merge anything, or push to `main` |
| Change code in `src/`, write tests in `tests/`, update `docs/` | Browse the web |
| Review a pull request and comment on it | See other repos, your computer, or any keys |

Every change it makes goes to a new branch called `claude/...`, and it posts a link to open a pull request. **A person
reads it, runs the tests in Studio, and merges.** Nothing it writes reaches the game without that.

## One-time setup (the repo owner, Catlyn: about 5 minutes)

Only a repo admin can do steps 1 and 2.

1. **Install the Claude GitHub app on this repo.** Go to https://github.com/apps/claude → *Install* (or *Configure*) →
   choose **Only select repositories** → pick `mada` → *Install*.
2. **Add one secret** so Claude can run. In the repo: *Settings → Secrets and variables → Actions → New repository
   secret*. Use **one** of these, **from Catlyn's own Claude account**:
   - `CLAUDE_CODE_OAUTH_TOKEN`: uses Catlyn's Claude Pro/Max subscription. On her computer with Claude Code installed,
     run `claude setup-token` in a terminal, sign in with her account, and paste the token it prints as the secret's
     value. Usage counts against her plan.
   - `ANTHROPIC_API_KEY`: a key from her account at https://console.anthropic.com (pay per use). Paste it as the
     secret's value.

   A secret can't be read back once saved, not even by admins. Don't paste it anywhere else (chat, issues, files).
3. **Merge the pull request that adds `.github/workflows/claude.yml`** into `main`. GitHub only runs this kind of
   workflow from the main branch, so it does nothing until then.
4. Recommended: **protect `main`** so nothing (person or bot) can push to it without a pull request: *Settings →
   Branches → Add branch protection rule* → branch name `main` → tick *Require a pull request before merging*.

Who can use it: anyone with write access to the repo (Catlyn, and collaborators she has added). Comments from anyone
else are ignored.

## How to ask

Open an issue (*Issues → New issue*), or comment on an existing issue or pull request, and start with `@claude`:

```
@claude Where is Bà Thu's Night 1 dialogue, and which lines are still DRAFT?
```

```
@claude Change the fish seller's notes clue: she should not name the sister. Keep it to the facts in story.md.
```

```
@claude Read docs/DECISIONS.md and list everything that still needs my review, one line each.
```

```
@claude The battery should be 1% per second, not 300 seconds. Change Config and the tests, and update DECISIONS.
```

On a pull request you can also ask it to review: `@claude review this` or comment on a single line with `@claude why is this here?`.

Claude first posts a short "working on it" comment and edits it as it goes. A question takes about a minute; a change can
take several. When it has changed files, the comment ends with a branch name and a **Create PR** link.

## After Claude makes a change

1. Click the **Create PR** link (or open a pull request from its `claude/...` branch into the branch you want).
2. Read the changes. Anything marked DRAFT is text for you to check against the story.
3. Run the tests in Studio on your computer: check out the branch, then `python tools/factory/test.py` (see
   `docs/FACTORY.md`). They must say PASS.
4. Merge when you're happy. If not, comment `@claude` on the pull request with what to change; it pushes to the same branch.

## Tips

- One request per comment works best. Say which file or section if you know it.
- It follows `AGENTS.md`: no gore, no invented story, anything it writes for players is marked DRAFT and logged in
  `docs/DECISIONS.md`.
- It forgets between comments except for what's in the issue or pull request thread, so keep a topic in one thread.
- Usage limits: each run is capped at 15 minutes (and 30 steps). It uses the plan or API key from setup step 2, plus
  GitHub Actions minutes (private repos get a free monthly allowance).
- **The bot watches its own weekly budget.** After every request it adds up what it has used since Monday and works out
  where that pace ends by Sunday. If it would run past the weekly budget, it posts one heads-up a day in the thread,
  tagging the repo owner: pause the bigger requests until Monday, or switch to Sonnet. Two repo variables control this
  (*Settings → Secrets and variables → Actions → Variables*):
  - `CLAUDE_MODEL`: the model. Not set = Opus 5.5. Set it to `claude-sonnet-5-5` for the lighter model; delete it to go back.
  - `WEEKLY_BUDGET_USD`: the weekly budget in dollars (not set = 40). With a subscription token this is Claude Code's
    estimate of what the same use would cost on the API, a gauge for how fast the week's allowance is going; raise or
    lower it until the heads-up comes at the right time.
  The run log (*Actions* tab → the run → *Budget guard*) shows each request's cost and the week's total.
- To switch it off: *Settings → Actions → General → Disable actions*, or delete `.github/workflows/claude.yml`.
- If it never answers: check *Actions* tab → the "Claude" run for an error (usually a missing secret or the app not installed).
