---
name: run
description: Use when ready to start autonomous execution of stories from prd.json. Launches either bash-loop or hook-loop execution mode.
---

# Run: Start Execution Loop

## Overview

Launch the autonomous execution loop that implements stories from prd.json one by one, with TDD discipline, verification, and two-stage review enforced in every iteration. This is Phase 3 of the pipeline, but can be used standalone if you already have a prd.json.

## Process

### 1. Locate prd.json
- Check `tasks/prd.json`
- If not found: suggest running `/plan` first
- Read and display summary: total stories, completed count, remaining count

### 2. Verify Prerequisites
- prd.json exists and has valid format
- At least one story has `passes: false`
- If all stories pass: suggest `/finish` instead

### 3. Choose Execution Mode

Present two options:

**1. Bash-loop (Recommended for 3+ stories)**
- Each iteration spawns a fresh Claude Code process
- Full context window per story (important: discipline rules consume context)
- Zero context pollution between stories
- Can run unattended (overnight)
- State persists via git + progress.txt + prd.json

**2. Hook-loop (Best for 1-2 stories)**
- Runs in current session via stop hook
- Real-time visibility
- Faster (no process spawn overhead)
- Shares same state format

### 4a: Bash-loop Setup
- Create git branch: `superralph/<feature>` (if not exists, from current branch)
- Initialize `tasks/progress.txt` if missing
- Print the exact command:
  ```
  /path/to/SuperRalph/scripts/ralph.sh --project-dir . --max-iterations 20
  ```
- Explain: "Run this in your terminal. Each iteration will pick the next incomplete story, implement it with TDD, verify, review, and commit. When all stories pass, it stops automatically."
- Update state: `phase: "run"`, `runMode: "bash-loop"`

### 4b: Hook-loop Setup
- Create git branch: `superralph/<feature>` (if not exists)
- Initialize `tasks/progress.txt` if missing
- Create/update `.claude/superralph-state.json` with:
  ```json
  {
    "phase": "run",
    "runMode": "hook-loop",
    "iteration": 1,
    "maxIterations": 20,
    "sessionId": "<current session ID>",
    ...
  }
  ```
- Start executing: read prd.json, pick first incomplete story, implement with TDD discipline
- The stop hook will handle iteration cycling

### 5. What Happens Each Iteration (Subagent Pipeline)

Explain to the user:
1. Read prd.json, progress.txt patterns, and design doc for context
2. Find next story where `passes: false`
3. **Spawn Implementer subagent** — implements the story with strict TDD (RED-GREEN-REFACTOR)
4. **Spawn Spec Reviewer subagent** — independently verifies all acceptance criteria are met (nothing missing, nothing extra)
5. **Spawn Code Quality Reviewer subagent** — checks correctness, cleanliness, consistency, security (categorizes issues as Critical/Important/Minor)
6. If reviews fail: fix issues and re-review (max 2 cycles)
7. Commit + update prd.json + append progress.txt
8. Web projects: Browser verification
9. On failure: Systematic debugging (4 phases)
10. All stories done → `<promise>COMPLETE</promise>`
