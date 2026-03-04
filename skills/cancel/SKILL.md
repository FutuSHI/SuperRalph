---
name: cancel
description: Use when needing to stop an active SuperRalph loop, whether bash-loop or hook-loop mode.
---

# Cancel: Stop Active Loop

## Overview

Terminate an active SuperRalph execution loop while preserving all completed work.

## Process

### 1. Check for Active Session
- Read `.claude/superralph-state.json`
- If no state file or phase is "idle": report "No active SuperRalph session to cancel."

### 2. Report Status
Display:
- Feature name
- Current phase
- Run mode (bash-loop or hook-loop)
- Iteration count
- How many stories completed vs remaining (read from tasks/prd.json)

### 3. Cancel Based on Mode

**Hook-loop:**
- Delete `.claude/superralph-state.json` (this stops the stop-hook from blocking exit)
- Report: "Hook-loop cancelled. Stop hook deactivated."

**Bash-loop:**
- The bash script runs in a separate terminal process
- Report: "To stop the bash-loop, press Ctrl+C in the terminal where ralph.sh is running."
- Set state phase to "idle" so the session-start hook stops showing active status

### 4. Preserve Work
- All completed stories remain committed in git
- prd.json reflects current progress (stories with `passes: true` stay true)
- progress.txt preserved with all logged learnings
- Branch is preserved

### 5. Next Steps
Suggest:
- "Run `/run` to resume execution later"
- "Run `/finish` if enough stories are complete"
- "Run `/debug` if you stopped due to a persistent issue"

## Important
- Cancel NEVER deletes the branch
- Cancel NEVER reverts commits
- Cancel NEVER modifies prd.json story statuses
- Cancel only removes the loop control state
