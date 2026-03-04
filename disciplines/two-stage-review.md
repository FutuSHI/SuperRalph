# Two-Stage Review Discipline

## Overview

Before committing code for a completed story, perform a two-stage self-review. The order is mandatory and cannot be reversed.

## Stage 1: Spec Compliance Review

**Question: Did I build exactly what was requested?**

Go through each acceptance criterion in the current story line by line:

- [ ] Criterion 1: Implemented? Evidence?
- [ ] Criterion 2: Implemented? Evidence?
- [ ] ...

Check for:

### Missing Requirements
- Did I implement everything requested?
- Are there acceptance criteria I skipped or partially addressed?
- Did I claim something works but didn't actually implement it?

### Extra/Unneeded Work (YAGNI)
- Did I build things that weren't in the acceptance criteria?
- Did I over-engineer or add unnecessary features?
- Did I add "nice to haves" that weren't requested?

### Misunderstandings
- Did I interpret requirements differently than intended?
- Did I solve the wrong problem?

**Result:**
- ✅ Spec compliant — all criteria met, nothing extra, nothing missing
- ❌ Issues found — list what's missing or extra, fix before proceeding

## Stage 2: Code Quality Review

**Only proceed here AFTER Stage 1 passes. NEVER reverse the order.**

**Question: Is the code well-built?**

Check for:

### Correctness
- Are there obvious bugs or edge cases?
- Does error handling cover realistic failure modes?
- Are there race conditions or state issues?

### Cleanliness
- Are names clear and descriptive?
- Is the code DRY (no unnecessary duplication)?
- Are functions/methods focused (single responsibility)?

### Consistency
- Does the code follow existing patterns in the codebase?
- Are conventions consistent (naming, structure, error handling)?

### Security (if applicable)
- Any injection vulnerabilities?
- Any exposed secrets or credentials?
- Input validation at system boundaries?

**Result:**
- ✅ Code quality approved — clean, correct, consistent
- ❌ Issues found — list issues, fix before committing

## Mandatory Rules

1. **Stage 1 ALWAYS before Stage 2.** Checking code quality of wrong-spec code is wasted effort.
2. **Both stages must pass.** Failing either = fix and re-review that stage.
3. **Be honest.** You're reviewing your own code. The temptation to approve everything is strong. Resist it.
4. **Log findings.** Record review results in progress.txt (even if both pass — "no issues" is a valid finding).

## In Ralph Iteration Context

This review happens AFTER verification (tests pass, typecheck clean) but BEFORE committing:

1. Verification passes ✅
2. Stage 1: Spec compliance ✅
3. Stage 2: Code quality ✅
4. THEN commit and update prd.json
