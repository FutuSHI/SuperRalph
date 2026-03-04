---
name: debug
description: Use when encountering bugs, test failures, build errors, or unexpected behavior. Activates systematic 4-phase debugging instead of guessing.
---

# Debug: Systematic Debugging

## Overview

When something breaks, don't guess. Follow the 4-phase systematic debugging process to find and fix the root cause efficiently. This skill can be invoked anytime — it's not tied to the pipeline state.

## The Iron Law

**NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.**

If you haven't completed Phase 1, you CANNOT propose fixes.

## The Four Phases

### Phase 1: Root Cause Investigation

**Do NOT skip this phase. Do NOT propose fixes yet.**

1. **Read error messages carefully.** They often contain the exact solution.
2. **Reproduce consistently.** Can you trigger the failure reliably? Exact steps? Every time?
3. **Check recent changes.** `git diff`, recent commits, dependency updates, environment changes.
4. **Trace data flow.** Where does the bad value originate? Keep tracing upstream until you find the source. Fix at source, not symptom.

For multi-component systems:
- Log what enters each component
- Log what exits each component
- Verify configuration propagation
- Check state at each boundary

### Phase 2: Pattern Analysis

1. **Find working examples.** Similar working code in the same codebase?
2. **Compare completely.** Read the working code in full, don't skim.
3. **Identify ALL differences.** Every difference matters.
4. **Understand dependencies.** What does the working code rely on?

### Phase 3: Hypothesis Testing

1. **Form ONE hypothesis:** "I think X is the root cause because Y."
2. **Test minimally:** SMALLEST possible change. One variable at a time.
3. **Verify:**
   - Worked → Phase 4
   - Didn't work → NEW hypothesis, back to step 1

### Phase 4: Implementation

1. **Write a failing test** that reproduces the bug
2. **Implement the fix** — address the root cause, ONE change
3. **Verify** — test passes? Other tests still pass? Issue actually resolved?

## The 3-Fix Rule

**If you have tried 3 fixes and none worked: STOP.**

This indicates an architectural problem, not a hypothesis problem. Do not attempt more fixes. Instead:
- Document what was tried and why each failed
- If in a SuperRalph session: leave the story as `passes: false` with detailed notes in progress.txt
- Escalate to human review

## Red Flags — You're Bypassing the Process

- "Quick fix for now"
- "Just try changing X"
- "I don't fully understand but this might work"
- "It's probably X" (without evidence)
- Each fix reveals a new problem in a different place
- Making multiple changes at once

## Integration with SuperRalph

When invoked during an active SuperRalph session:
- Log all debugging steps in `tasks/progress.txt`
- Include: what was investigated, hypotheses tested, evidence found
- Future iterations read this to avoid repeating failed approaches
