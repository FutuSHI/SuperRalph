<p align="center">
  <img src="assets/banner.jpg" alt="SuperRalph" width="700">
</p>

<h3 align="center"><i>Your AI agent just got superpowers AND learned discipline.</i></h3>

> One command. One plugin. From shower thought to merge-ready branch — with TDD baked into every single step.

---

## The Problem

You're using Claude Code. You discover **Superpowers** by [obra](https://github.com/obra) — brilliant development discipline (TDD, code review, verification). Then you find **Ralph Loop** by [snarktank](https://github.com/snarktank) / [Geoffrey Huntley](https://github.com/ghuntley) — autonomous PRD-driven execution that just *keeps going*.

You install both. You love both. And then you spend the next hour figuring out how to make them talk to each other.

**We got tired of juggling two plugins.** So we fused them.

SuperRalph takes the disciplined engineering rigor of Superpowers and the relentless autonomous execution of Ralph Loop, and welds them into a single plugin that just works.

## Before vs After

```
BEFORE (two plugins, manual coordination):
──────────────────────────────────────────
  You: "Add user auth"
  → Open Superpowers, brainstorm
  → Manually write a PRD
  → Switch to Ralph Loop, feed it the PRD
  → Hope it writes tests (it might not)
  → Manually check if stories are done
  → Stitch everything together yourself
  → 😩

AFTER (SuperRalph):
────────────────────
  You: /superRalph "Add user authentication"
  → Go get coffee ☕
  → Come back to a tested, reviewed, merge-ready branch
  → 🎉
```

## Installation

Two commands. That's it.

```bash
/plugin marketplace add FutuSHI/SuperRalph
/plugin install superralph@superralph
```

No config files. No YAML to maintain. Install and go.

### Prerequisites

- **[Claude CLI](https://docs.anthropic.com/en/docs/claude-code)** — Claude Code must be installed
- **[jq](https://jqlang.github.io/jq/)** — Used for JSON processing in scripts
- **[perl](https://www.perl.org/)** — Used for template placeholder replacement (pre-installed on macOS/Linux)

> **Note:** The banner image (`assets/banner.jpg`) is a placeholder — replace it with your own project banner.

## What Happens When You Type `/superRalph`

Let's say you run:

```
/superRalph "Add rate limiting to the API"
```

Here's what unfolds:

**Phase 1 — THINK** 🧠 &nbsp; SuperRalph brainstorms your feature like an overprepared architect. It explores edge cases you didn't think of ("What about burst traffic?"), identifies constraints ("The existing middleware pipeline..."), and produces a structured PRD. You understand *what* to build before a single line of code exists.

**Phase 2 — PLAN** 📋 &nbsp; The PRD transforms into an executable `prd.json` — each story gets acceptance criteria, complexity estimates, and dependency ordering. This plan is now the contract. No story gets implemented without clear criteria for "done."

**Phase 3 — RUN** 🔨 &nbsp; Stories execute one at a time in a strict TDD loop:

1. Write a failing test (red)
2. Write the minimum code to pass (green)
3. Refactor while keeping tests green
4. Run code review checks
5. Mark complete, pick up the next story
6. Repeat until the plan is done

**Phase 4 — FINISH** ✅ &nbsp; Final verification across all stories. A session summary is generated. The branch is clean, tested, reviewed, and ready for your `git push`.

### The Flow

```
  🧠 THINK ──→ 📋 PLAN ──→ 🔨 RUN ──→ ✅ FINISH
     │            │           │           │
  Brainstorm    Stories    TDD loop    Verify &
  + PRD       + criteria  per story    merge-ready
```

## All Commands

| Command | What it does |
|---------|-------------|
| `/superRalph` | The full ride. THINK → PLAN → RUN → FINISH, all automatic. |
| `/think` | Just the brainstorming phase. Explore the problem, produce a PRD. |
| `/plan` | Got a PRD already? Convert it into an executable `prd.json`. |
| `/run` | Got a `prd.json`? Start the TDD execution loop. |
| `/finish` | All stories done? Run final verification and prepare for merge. |
| `/debug` | Something broke? Systematic debugging: root cause → hypothesis → fix → test. |
| `/cancel` | Stop the loop now. Progress is preserved, workspace stays clean. |

## What Makes This Different

### 🔒 TDD is not optional

Every single story goes through red → green → refactor. No exceptions. Code written before a test exists gets deleted and restarted. This isn't a suggestion — it's enforced.

### 🧠 Three-layer memory

The agent doesn't forget what it's doing mid-session:

- **`prd.json`** — Task state: which stories pass, which failed, what's next
- **`progress.txt`** — Experience log: learnings, patterns, gotchas from previous iterations
- **`design doc`** — Architectural decisions made during THINK, referenced in every iteration

### 🔄 Two execution modes

- **Bash-loop** (default) — For multi-story features. Spawns fresh Claude processes per iteration, maintaining state across complex dependency chains.
- **Hook-loop** (lightweight) — For quick iterations. Runs within Claude Code's hook system. Perfect for single-story tasks and rapid prototyping.

### 🔍 Auto project detection

SuperRalph detects your stack (React, Next.js, Express, static HTML, etc.) and adjusts its TDD strategy, test runner config, and review checks accordingly.

### 💾 Resumable by design

If the loop crashes mid-execution, resume from exactly where it stopped. `/cancel` always leaves the workspace recoverable. No orphaned state, no corrupted plans.

## Credits

SuperRalph stands on the shoulders of two excellent projects:

- **[Superpowers](https://github.com/obra/superpowers)** by [obra](https://github.com/obra) — The development discipline engine: TDD, code review, verification, systematic debugging
- **[Ralph Loop](https://github.com/snarktank/ralph)** by [snarktank](https://github.com/snarktank) / [Geoffrey Huntley](https://github.com/ghuntley) — The autonomous PRD-driven execution loop

This project wouldn't exist without their work. We just couldn't stop ourselves from combining them.

## License

MIT
