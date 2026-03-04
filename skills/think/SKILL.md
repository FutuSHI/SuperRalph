---
name: think
description: Use when brainstorming a feature idea, creating requirements, or the user wants to design before building. Produces a design doc and PRD without starting implementation.
---

# Think: Brainstorming + PRD Generation

## Overview

Turn a rough idea into a fully formed design and Product Requirements Document through collaborative dialogue. This is Phase 1 of the SuperRalph pipeline, but can be used standalone.

<HARD-GATE>
Do NOT write any code or take any implementation action. This skill produces design documents and PRDs only.
</HARD-GATE>

## Process

### 1. Detect Project Context
- Check language, framework, existing structure
- Auto-detect Web project (package.json with web framework deps)
- Note existing patterns and conventions

### 2. Brainstorming
- Ask clarifying questions ONE AT A TIME
- Prefer multiple choice when possible (lettered options: A, B, C, D)
- Focus on: purpose, constraints, success criteria, scope
- Only one question per message
- Understand before proposing

### 3. Propose Approaches
- Present 2-3 approaches with trade-offs
- Lead with recommended option, explain why
- Let user choose

### 4. Present Design
- Present in sections, scaled to complexity
- After each section ask: "Does this look right?"
- Cover: architecture, components, data flow, testing
- YAGNI ruthlessly

### 5. Generate PRD
After design approval, create PRD at `tasks/prd-<feature>.md` with:
- Introduction/Overview
- Goals (specific, measurable)
- User Stories (each with: title, "As a... I want... so that...", acceptance criteria checklist)
- Functional Requirements (FR-1, FR-2, ...)
- Non-Goals (what this does NOT include)
- Technical Considerations (optional)

User stories should be:
- Small enough for one context window
- Ordered by dependency (schema → backend → UI)
- Have verifiable acceptance criteria (not vague)

### 6. Save Artifacts
- Design doc → `docs/plans/YYYY-MM-DD-<feature>-design.md`
- PRD → `tasks/prd-<feature>.md`
- Update `.claude/superralph-state.json`: `phase: "plan"`, feature, designDoc, prdFile
- Announce: "Design and PRD complete. Run /plan to convert to prd.json, or /superRalph to continue the pipeline."

## Key Principles
- One question at a time
- Multiple choice preferred
- YAGNI ruthlessly
- Explore alternatives before settling
- Incremental validation
- Scale each section to its complexity
