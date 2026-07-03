# Agentic Coding: Cognitive Debt Problem

Working artifact. Captures the problem, the mechanism, and the workflow shape that solves it. Living doc — update as understanding sharpens.

## BLUF

Letting agents run end-to-end produces **cognitive debt**: code I don't recognize, didn't decide on, can't review, and that becomes context-poison for the next agent. Front-loading specs and back-loading review both fail. The fix is **continuous, in-loop review at small granularity** — and Neovim is the surface where that happens.

## Problem

I use Claude Code heavily. When I let it run unsupervised:

1. **It produces code I don't like.** Style, architecture, naming, abstractions. Tests pass; taste fails.
2. **Bad code becomes context.** The next agent reads the mud and writes more mud. The codebase converges on its worst output, not its best.
3. **Tests calcify the wrong domain model.** Once a test pins a bad name or a bad shape, future agents work around it — fork into parallel domain models and parallel services just to get green.
4. **I stop reviewing tests.** Generated tests reference unfamiliar classes/functions/objects. To review I have to untangle the implementation. So I skip. Now nothing is gating quality.
5. **Big-bang review fails.** By the time I'm staring at a 40-file diff, my brain capitulates. I rubber-stamp or rewrite from scratch. Both bad.
6. **Refactoring debt is the bill.** I was just asked to refactor a core feature and the agent-grown code is a mess. Cost of unsupervised generation = cost of human refactor + cost of trust I now have to rebuild.

## Why obvious fixes don't work

- **More agents** (refactorer, reviewer, standards-enforcer): expensive. Compounds over weeks. Doesn't scale to home use. Feels like buying review with tokens instead of attention.
- **Better specs up-front**: design decisions emerge during code. Specs can't predict them. Front-loading dumps real decisions onto an agent that has no taste.
- **Better tests up-front**: green tests don't catch bad shape. And generated tests are the calcification vector.
- **Bigger review at the end**: cognitive load exceeds budget. I miss things. Mud lands.

## Mechanism (why it compounds)

```
agent writes code  →  becomes context  →  next agent reads context
       ↑                                          ↓
       └────────── more code in same style ←──────┘
```

The codebase is a **prompt** for the next iteration. Every unreviewed file is a vote for that file's style. Drift is positive feedback.

## What I want

- **Stay in flow.** Writing code by hand keeps skills sharp and makes review trivial because I already understand what's there.
- **Compromise at work.** Hand-write the skeleton (types, function signatures, test stubs); agent fills bodies; I review per chunk.
- **Review during, not after.** Each agent action gets a glance before it lands.
- **Reject without ceremony.** Bad output undone with one keystroke, not a re-prompt cycle.
- **Discover as I go.** When implementation reveals a better design, change the spec — don't fight tests written for the old one.

## Objective function

Maximize:

```
                value added
─────────────────────────────────────────
   tokens used   ×   human attention
```

All three axes matter:

- **Value added** = correct code that compounds well as future context (high quality, low calcification risk).
- **Tokens used** = agent rounds. Cheap individually, expensive when wasted on salvage or spent reviewing dross.
- **Human attention** = scarcest resource. Limited per day, non-renewable per session, depleted by context-switching.

**Anti-patterns (low ratio):**

| Pattern | Why bad |
|---|---|
| Token-heavy salvage | Re-prompting to fix bad output spends tokens AND attention; reject-the-branch is cheaper |
| Attention on T0 | Reviewing boilerplate burns the scarcest axis on the lowest-value work |
| Fire-and-forget T3 | Future cost (mud-as-context) doesn't show in current ledger — bills later |
| Uniform gate | Treats every change as T2/T3; you become the GIL |
| Uniform free | Treats every change as T0; calcification debt accrues |

**High-ratio moves:**

| Move | Mechanism |
|---|---|
| Hand-write T3 skeleton | Zero tokens, high attention well-spent (novel design = highest leverage point) |
| Agent fills bodies of T3 stubs | Tokens cheap, attention cost low because skeleton already constrains shape |
| Cheap reviewer pre-filter | Tokens spent so attention isn't |
| Worktree-per-task batching | Attention amortized over PR-level diff, not per-edit |
| Reject branches, don't salvage | Caps token spend; prevents salvage attention drain |
| Glossary in agent prompt | One-time attention cost prevents N token+attention rounds of name-fighting |

## Decision rule (at task dispatch)

Before sending a task to an agent, estimate:

1. **Tier** (T0–T3) based on trust region × novelty × risk
2. **Expected execution mode:**
   - T0: agent runs free, batch review, no diff-gate
   - T1: agent runs free, PR-level review with reviewer-agent pre-filter
   - T2: per-turn diff-gate in nvim, small chunks
   - T3: hand-write skeleton, agent fills bodies only, live review

3. **Bail conditions:**
   - If attention budget low → escalate tier-down (defer T2/T3 to later session)
   - If value uncertain → spike with cheapest mode first, escalate if it matters
   - If salvage round 2 → kill branch, restart with tighter scaffold

## Failure modes the workflow must prevent

| Failure | Trigger | Detection |
|---|---|---|
| Calcified tests | Agent writes tests asserting on internal shape | Review tests *before* implementation |
| Parallel domain models | Agent invents new names instead of reusing existing | Symbol outline + glossary check |
| Mud-as-context | Unreviewed code feeds next session | Per-turn diff review |
| Rubber-stamp | Diff too large to read | Small chunks, immediate review |
| Test review skipped | Test references unknown symbols | Force test-first, hand-write or hand-review |

## Workflow shape (target)

1. **I scaffold by hand in nvim.** Types, signatures, doc comments stating intent, test names (no bodies).
2. **Agent fills bodies in small chunks.** One function or one test body per turn.
3. **Per-turn diff review in nvim.** Inline overlay shows what changed since last ack. I either ack (commit-worthy) or revert.
4. **Tests authored by me, never by agent.** Or: agent proposes, I rewrite before running.
5. **Architectural lints as diagnostics.** Bad patterns surface as red squigglies during the loop, not as PR comments.
6. **Glossary file is canonical.** Agent prompt includes it. Diffs to it require explicit ack.

## Constraints

- Work environment requires AI assistance — can't pure-handwrite everything.
- Home use: cost-sensitive. No "throw 5 review agents at it."
- Existing tooling: Claude Code (terminal), full discovery/bruno plugin suite available.
- Editor: Neovim 0.12, this config.

## Open questions

- How to mark "agent-touched but unreviewed" symbols visibly?
- Where does the glossary live — repo root? per-package?
- Do I commit per turn, or stage per turn and commit per feature?
- How to surface architectural reviews without paying per-edit token cost?

## Recommendations

Ranked by leverage. Implement top-down; stop when behavior shifts.

### Config review summary

Strong fits already in config:
- `diffview.nvim` — primary review surface, underused
- `gitsigns.nvim` hunk ops — per-hunk inline reject
- `trouble.nvim` — diagnostic panel, can host reviewer-agent output
- `todo-comments.nvim` — repurpose `REVIEW:` keyword for agent self-flags
- Telescope `lsp_document_symbols` — modal symbol scan

Gaps:
- No diff-vs-arbitrary-reference (gitsigns is HEAD-only)
- No persistent symbol outline
- No Claude integration in nvim (forces terminal context-switch)
- No "files under review" pin/queue

### 1. `mini.diff` with manual reference — per-turn diff-gate

Diff vs *"the moment I last said OK"*, not vs HEAD. Set reference at session start; every agent edit shows inline overlay until ack or revert.

Highest-leverage single addition.

### 2. `coder/claudecode.nvim` (or `greggh/claude-code.nvim`)

Claude inside nvim. Send selections from hand-written stub → receive diff in nvim buffer. Removes terminal context-switch.

### 3. `aerial.nvim` — persistent symbol outline

When tests reference 12 unknown symbols, sidebar lets you scan structure without reading bodies. Complements treesitter-context.

### 4. `nvim-lint` + custom reviewers — agents as diagnostics

Wrap `bruno:test-critic` and `discovery:architecture-reviewer` as linter shells emitting parseable output. Bad patterns surface as red squigglies inline.

Cost control: only lint session-modified files. Sample, don't run on every save.

### 5. `ThePrimeagen/harpoon` — pin "files under review"

Cycle 5 agent-edited files quickly without losing place. Different from buffer list (noisy) or marks (no UI).

### 6. Custom: agent-touched symbol highlighter (defer)

Track agent-introduced symbols in session. Render virt-text marker until cursor-acked. Direct attack on "unfamiliar test symbols" failure mode.

Sketch: `BufWritePost` → treesitter-extract added identifiers vs reference → extmark them → `<leader>ak` clears.

Build only after #1–4 are habit.

### 7. `GLOSSARY.md` convention (no plugin)

Repo-root canonical names. Include in agent system prompt. `BufWritePost` hook on glossary loud-warns on changes.

### Keymap namespace: `<leader>a*` = agent ops

| Key | Action |
|---|---|
| `<leader>ar` | Set diff reference |
| `<leader>aa` | Ack all (reset reference) |
| `<leader>ah` | Apply hunk |
| `<leader>aH` | Reject hunk |
| `<leader>ad` | Show all unreviewed diffs |
| `<leader>ac` | Toggle Claude in nvim |
| `<leader>as` | Send selection to Claude |
| `<leader>aD` | Last Claude response as diff |
| `<leader>oo` | Toggle aerial outline |
| `<leader>h*` | Harpoon |

Note: `<leader>cs` (colorscheme picker) does not collide if Claude lives under `<leader>a*`.

### Suggested first move

Pick one:
- **#1 mini.diff** — single plugin, biggest behavior shift
- **#2 claudecode.nvim** — if terminal context-switch is bigger drain
- **GLOSSARY + protocol** — no plugins, cheapest to test
