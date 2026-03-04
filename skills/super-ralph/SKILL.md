---
name: superRalph
description: Use when starting a new feature, building something from scratch, or the user says /superRalph. Full pipeline from brainstorming to merged code with TDD discipline and autonomous execution.
---

# SuperRalph: Full Pipeline

## Overview

One command to go from idea to merged code. Combines Superpowers' development discipline (brainstorming, TDD, code review, verification) with Ralph Loop's autonomous execution (PRD-driven iteration loop).

**Pipeline:** THINK → PLAN → RUN → FINISH

<HARD-GATE>
Do NOT write any code, scaffold any project, or take any implementation action until you have completed the THINK phase and the user has approved the design. This applies to EVERY project regardless of perceived simplicity.
</HARD-GATE>

## State Management

Read/write `.claude/superralph-state.json` at each phase transition:
```json
{
  "phase": "think|plan|run|finish|idle",
  "feature": "<feature-name>",
  "branchName": "superralph/<feature-name>",
  "designDoc": "docs/plans/YYYY-MM-DD-<feature>-design.md",
  "prdFile": "tasks/prd-<feature>.md",
  "prdJson": "tasks/prd.json",
  "runMode": "bash-loop|hook-loop",
  "iteration": 0,
  "maxIterations": 20,
  "completionPromise": "COMPLETE",
  "startedAt": "<ISO timestamp>",
  "webProject": false
}
```

## Phase 1: THINK (Interactive)

### Step 1: Detect Project Context
- Check language (look at file extensions, config files)
- Check framework (package.json, Cargo.toml, go.mod, requirements.txt, etc.)
- Auto-detect Web project: package.json with react/next/vue/angular/svelte/solid/astro/remix/gatsby → webProject = true

### Step 2: Brainstorming
- Ask clarifying questions ONE AT A TIME
- Prefer multiple choice questions when possible
- Focus on: purpose, constraints, success criteria, scope boundaries
- Understand the problem before proposing solutions

### Step 3: Propose Approaches
- Present 2-3 different approaches with trade-offs
- Lead with your recommended option and explain why
- Let user choose

### Step 4: Present Design
- Present design in SECTIONS, scaled to complexity
- After each section, ask: "Does this look right so far?"
- Cover: architecture, components, data flow, error handling, testing approach
- Be ready to revise based on feedback
- YAGNI ruthlessly — remove anything not directly needed

### Step 5: Save Artifacts
- Save design doc: `docs/plans/YYYY-MM-DD-<feature>-design.md`
- Generate PRD markdown: `tasks/prd-<feature>.md` with:
  - Introduction/Overview
  - Goals (bullet list)
  - User Stories (each with: title, description "As a... I want... so that...", acceptance criteria checklist)
  - Functional Requirements (numbered: FR-1, FR-2...)
  - Non-Goals
  - Technical Considerations (optional)
- Update state: `phase: "plan"`

### Step 6: Transition
- Announce: "Design approved. Moving to PLAN phase to create prd.json."
- Proceed to Phase 2

## Phase 2: PLAN (Semi-automatic)

### Step 1: Convert PRD to prd.json
- Read the PRD markdown from tasks/prd-<feature>.md
- Convert to prd.json format:
  ```json
  {
    "project": "<project name>",
    "branchName": "superralph/<feature-name-kebab>",
    "description": "<feature description>",
    "designDoc": "<path to design doc>",
    "userStories": [...]
  }
  ```

### Step 2: Apply Granularity Rules
- Each story must be completable in ONE context window (one Ralph iteration)
- If a story is too big, split it
- Right-sized: "Add a database column", "Create a UI component", "Add a filter dropdown"
- Too big: "Build the entire dashboard", "Add authentication"
- Order by dependency: schema → backend → UI

### Step 3: Enhance Acceptance Criteria
Every story automatically gets these criteria appended:
- "All tests pass"
- "Typecheck passes"
- "Verification evidence provided"
- If webProject AND story modifies UI: "Verify in browser using dev-browser skill"

Every story should include TDD-oriented criteria:
- "Write failing test before implementation"

### Step 4: User Approval
- Present the complete prd.json to the user
- Wait for approval before proceeding
- Update state: `phase: "run"`

## Phase 3: RUN (Autonomous Loop)

### Step 1: Choose Mode
Prompt user:
1. **Bash-loop (Recommended)** — Runs unattended. Each iteration gets a fresh context window. Best for 3+ stories. Run with: `./path/to/ralph.sh --project-dir . --max-iterations N`
2. **Hook-loop** — Runs in current session. Real-time visibility. Best for 1-2 stories.

### Step 2: Setup
- Create git branch: `superralph/<feature-name>` (if not exists)
- For bash-loop: print the exact command to run and explain what it does
- For hook-loop: create `.claude/superralph-state.json` with runMode: "hook-loop", start executing

### Step 3: Execution (each iteration)
Each iteration follows this inner loop:
1. Read prd.json → find next incomplete story
2. Read progress.txt + design doc for context
3. **TDD Discipline:** Write failing test FIRST → verify RED → implement → verify GREEN → refactor
4. **Verification Gate:** Run all checks, provide evidence
5. **Two-Stage Review:** Spec compliance first, then code quality
6. Pass → commit + update prd.json (passes: true) + append progress.txt
7. [Web projects] Browser verification
8. On failure → **Systematic Debugging** activates (4 phases)

### Step 4: Completion
When all stories have `passes: true`:
- Output `<promise>COMPLETE</promise>`
- Update state: `phase: "finish"`
- Proceed to Phase 4

## Phase 4: FINISH (Interactive)

### Step 1: Verify
- Run full test suite
- Confirm all tests pass with evidence

### Step 2: Summary
Show:
- Stories completed (list with IDs and titles)
- Files changed
- Test results

### Step 3: Present Options
Exactly 4 options:
1. Merge locally to base branch
2. Push and create Pull Request
3. Keep branch as-is (I'll handle it)
4. Discard work (requires typing "discard" to confirm)

### Step 4: Execute
- Execute the chosen option
- Archive: prd.json + progress.txt + design doc → `archive/YYYY-MM-DD-<feature>/`
- Clean up: set state to `phase: "idle"`

## Anti-Pattern Defenses

### "This is too simple for the full pipeline"
Every project goes through all 4 phases. Simple projects are where unexamined assumptions cause the most waste. The THINK phase can be short (a few questions, a brief design), but it CANNOT be skipped.

### "Let me just start coding"
NO. THINK phase first. Always. The design doc takes 5 minutes. Debugging a wrong approach takes hours.

### "I already know what to build"
You know what YOU think. The brainstorming reveals what you HAVEN'T thought about.
