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

### 5. What Happens Each Iteration

Explain to the user:
1. Read prd.json → find next story where `passes: false`
2. Read progress.txt for past learnings + design doc for architectural context
3. TDD: Write failing test → verify RED → implement → verify GREEN → refactor
4. Verification: Run checks, provide evidence
5. Two-stage review: Spec compliance → code quality
6. Commit + update prd.json + append progress.txt
7. Web projects: Browser verification
8. On failure: Systematic debugging (4 phases)
9. All stories done → `<promise>COMPLETE</promise>`
