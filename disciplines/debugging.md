# Systematic Debugging Discipline

## The Iron Law

**NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.**

If you haven't completed Phase 1, you cannot propose fixes. Guessing wastes iterations.

## The Four Mandatory Phases

### Phase 1: Root Cause Investigation

1. **Read error messages carefully.** They often contain the exact solution.
2. **Reproduce consistently.** Can you trigger the failure reliably? What are the exact steps?
3. **Check recent changes.** What changed since it last worked? `git diff`, recent commits, dependency updates.
4. **Trace data flow.** Where does the bad value originate? What called this with the bad value? Keep tracing upstream until you find the source. Fix at the source, not at the symptom.

### Phase 2: Pattern Analysis

1. **Find working examples.** Is there similar working code in the codebase?
2. **Compare against references.** Read the working code COMPLETELY, don't skim.
3. **Identify differences.** Every difference matters, however small.
4. **Understand dependencies.** What other components, settings, or assumptions does the working code rely on?

### Phase 3: Hypothesis Testing

1. **Form a single hypothesis:** "I think X is the root cause because Y."
2. **Test minimally:** Make the SMALLEST possible change to test this hypothesis. One variable at a time.
3. **Verify:** Did it work?
   - YES → proceed to Phase 4
   - NO → form a NEW hypothesis, return to step 1

### Phase 4: Implementation

1. **Write a failing test** that reproduces the bug (simplest possible reproduction)
2. **Implement the fix** — address the root cause identified in Phase 1-3, ONE change
3. **Verify the fix** — test passes? Other tests still pass? Issue actually resolved?

## The 3-Fix Rule

**If you have tried 3 fixes and none worked: STOP.**

This is not a hypothesis problem. This is an architectural problem. Do not attempt more fixes. Instead:
- Log what you tried and why each failed in progress.txt
- Leave the story as `passes: false`
- Note the architectural concern for future iterations or human review

## Red Flags — STOP and Follow the Process

- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes at once, run tests"
- "I don't fully understand but this might work"
- "It's probably X, let me fix that" (without evidence)
- Each fix reveals a new problem in a different place (symptom of architectural issue)

## In Ralph Iteration Context

When a story's tests or typecheck fail during implementation:
1. Activate this debugging process immediately
2. DO NOT guess and retry randomly — you have limited iterations
3. Log ALL debugging steps in progress.txt so future iterations don't repeat the same failed approaches
4. If the 3-fix rule triggers, leave the story for the next iteration with detailed notes
