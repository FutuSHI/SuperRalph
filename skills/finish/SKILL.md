---
name: finish
description: Use when all stories are complete and it's time to merge, create a PR, or wrap up the feature branch. Also use after the execution loop completes.
---

# Finish: Wrap Up and Merge

## Overview

Complete the development cycle by verifying all work, presenting merge options, and cleaning up. This is Phase 4 of the pipeline, but can be used standalone to wrap up any feature branch.

## Process

### 1. Verify All Work
- Run the project's full test suite
- Run typecheck if applicable
- Provide verification evidence (paste test output)
- If ANY tests fail: STOP. Do not proceed. Show failures and suggest `/debug`.

### 2. Show Summary
Display:
- Feature name and branch
- Stories completed (from prd.json, list IDs + titles)
- Total files changed (git diff --stat against base branch)
- Test results (pass count, any warnings)

### 3. Present Exactly 4 Options

1. **Merge locally** — Checkout base branch, pull latest, merge feature branch, verify tests post-merge, delete feature branch
2. **Push and create PR** — Push branch to remote, create PR with auto-generated body (summary from prd.json stories + progress highlights), provide PR URL
3. **Keep branch as-is** — Leave the branch for manual handling later. Do NOT clean up.
4. **Discard work** — Requires user to type "discard" to confirm. Delete branch, remove state file.

### 4. Execute Choice

**Option 1 (Merge):**
1. `git checkout <base-branch>`
2. `git pull` (if remote exists)
3. `git merge <feature-branch>`
4. Run tests to verify merge is clean
5. `git branch -d <feature-branch>`

**Option 2 (PR):**
1. `git push -u origin <feature-branch>`
2. Create PR with title from feature name and body with:
   - Summary (from prd.json description)
   - Stories completed (list)
   - Key changes (from progress.txt highlights)
3. Report PR URL

**Option 3 (Keep):**
1. Report: "Branch `<name>` kept as-is. Run `/finish` again when ready."
2. Do NOT delete state or archive

**Option 4 (Discard):**
1. Ask user to type "discard" to confirm
2. `git checkout <base-branch>`
3. `git branch -D <feature-branch>`
4. Clean up state file

### 5. Archive (for options 1, 2, 4)
- Copy to `archive/YYYY-MM-DD-<feature>/`:
  - tasks/prd.json
  - tasks/progress.txt
  - design doc (from state)
- Set state: `phase: "idle"`
- Delete `.claude/superralph-state.json` or set phase to idle

## Red Flags
- Never proceed with failing tests
- Never force-push without explicit user request
- Never delete work without typed confirmation
- Never present open-ended questions instead of the 4 structured options
