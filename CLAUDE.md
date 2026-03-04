# SuperRalph Plugin

You have the **SuperRalph** plugin installed — a unified development powerhouse combining Superpowers discipline (TDD, code review, verification) with Ralph Loop autonomous execution (PRD-driven iteration).

## Available Commands

| Command | When to Use |
|---------|-------------|
| `/superRalph` | Starting a new feature from scratch. Full pipeline: THINK → PLAN → RUN → FINISH |
| `/think` | Brainstorming an idea, designing before building. Produces design doc + PRD |
| `/plan` | Already have a PRD, need to convert to prd.json for execution |
| `/run` | Already have prd.json, ready to start the autonomous execution loop |
| `/finish` | All stories complete, time to merge/PR/wrap up |
| `/debug` | Encountering bugs, test failures, or unexpected behavior |
| `/cancel` | Stop an active execution loop |

## When to Invoke

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a SuperRalph skill applies to what you are doing, you MUST invoke it.

- User wants to build something → `/superRalph`
- User has a feature idea → `/think`
- User has a PRD → `/plan`
- User has prd.json → `/run`
- Work is done → `/finish`
- Something is broken → `/debug`
- Need to stop → `/cancel`
</EXTREMELY-IMPORTANT>

## Core Disciplines

Every execution iteration enforces:
1. **TDD** — Write failing test FIRST, then implement. Code before test = delete and restart.
2. **Verification** — No completion claims without evidence. Run the command, paste the output.
3. **Two-Stage Review** — Spec compliance first (nothing missing, nothing extra), then code quality.
4. **Systematic Debugging** — 4 phases: root cause → pattern analysis → hypothesis → implementation. No guessing.

## State

Active session state is stored in `.claude/superralph-state.json`. The session-start hook will display status if a session is active.

## Execution Modes

- **Bash-loop** (primary): `scripts/ralph.sh` — spawns fresh Claude process per iteration, best for multi-story features
- **Hook-loop** (lightweight): stop hook intercepts exit, best for 1-2 story quick iterations

## Three-Layer Memory

1. **prd.json** — Task state (which stories pass/fail)
2. **progress.txt** — Experience log (learnings, patterns, gotchas)
3. **Design doc** — Architectural decisions (referenced each iteration)
