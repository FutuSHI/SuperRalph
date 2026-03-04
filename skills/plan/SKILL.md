---
name: plan
description: Use when converting a PRD to executable prd.json format. Takes an existing PRD markdown and produces a structured prd.json ready for the execution loop.
---

# Plan: PRD to prd.json Conversion

## Overview

Convert a Product Requirements Document (markdown) into the structured prd.json format that SuperRalph's execution loop uses. This is Phase 2 of the pipeline, but can be used standalone if you already have a PRD.

## Process

### 1. Locate PRD
- Check `.claude/superralph-state.json` for `prdFile` path
- Or look for `tasks/prd-*.md` files
- If no PRD found: suggest running `/think` first

### 2. Read and Parse PRD
- Extract user stories with their acceptance criteria
- Extract project name, description
- Note dependencies between stories

### 3. Apply Granularity Rules

**Story Sizing (The Number One Rule):**
Each story must be completable in ONE Ralph iteration (one context window).

Right-sized:
- Add a database column and migration
- Create a UI component for an existing page
- Add a filter dropdown to a list
- Update a server action with new logic

Too big (must split):
- "Build the entire dashboard" → split into schema, queries, UI, filters
- "Add authentication" → split into schema, middleware, login UI, session handling

**Rule of thumb:** If you can't describe the change in 2-3 sentences, split it.

### 4. Order by Dependencies
1. Schema/database changes (migrations)
2. Server actions / backend logic
3. UI components that use the backend
4. Dashboard/summary views that aggregate data

No story should depend on a later story.

### 5. Enhance Acceptance Criteria

Auto-append to EVERY story:
- "All tests pass"
- "Typecheck passes"
- "Verification evidence provided"

Auto-append to UI stories (when webProject is true):
- "Verify in browser using dev-browser skill"

Ensure TDD criteria:
- "Write failing test before implementation"

Ensure all criteria are VERIFIABLE (not vague):
- Good: "Add status column with default 'pending'"
- Bad: "Works correctly"

### 6. Generate prd.json

```json
{
  "project": "<project name>",
  "branchName": "superralph/<feature-kebab>",
  "description": "<description from PRD>",
  "designDoc": "<path to design doc>",
  "userStories": [
    {
      "id": "US-001",
      "title": "<title>",
      "description": "As a <user>, I want <feature> so that <benefit>",
      "acceptanceCriteria": ["criterion 1", "criterion 2", ...],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

### 7. Present for Approval
- Display the complete prd.json to the user
- Wait for approval
- Save to `tasks/prd.json`
- Update state: `phase: "run"`
- Announce: "prd.json ready. Run /run to start execution, or /superRalph to continue the pipeline."

## Archiving
If `tasks/prd.json` already exists with a different `branchName`:
- Archive it to `archive/YYYY-MM-DD-<old-feature>/`
- Then write the new prd.json
