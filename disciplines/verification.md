# Verification Discipline

## The Iron Law

**NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.**

If you haven't run the verification command in this iteration, you cannot claim it passes. "Should work" is not evidence. "Probably passes" is not evidence. Only command output is evidence.

## The 5-Step Gate

Before marking ANY story as `passes: true`:

### 1. IDENTIFY
What commands prove each acceptance criterion is met?

### 2. RUN
Execute each verification command. Full command, not partial. Fresh run, not cached.

### 3. READ
Read the COMPLETE output. Check exit code. Count failures. Don't skim.

### 4. VERIFY
Does the output actually confirm the claim?
- If NO: State actual status WITH the evidence (paste output)
- If YES: State claim WITH the evidence (paste output)

### 5. CLAIM
Only NOW may you claim the criterion is met.

Skip any step = the claim is unverified.

## Verification Requirements

| Claim | Requires | NOT Sufficient |
|-------|----------|----------------|
| "Tests pass" | Test output showing 0 failures | Previous run, "should pass", partial run |
| "Typecheck clean" | Typecheck output showing 0 errors | "No changes to types" |
| "Build succeeds" | Build command exit code 0 | Linter passing |
| "Story complete" | Every criterion verified with evidence | "I implemented everything" |
| "Bug fixed" | Test for the bug passes | "Code changed, should be fixed" |

## Forbidden Language

These words/phrases indicate unverified claims. If you catch yourself using them, STOP and run verification:

- "should work now"
- "probably passes"
- "seems to be working"
- "I think it's fixed"
- "I'm confident that..."
- "based on my changes..."
- "logically, this should..."

## In Ralph Iteration Context

Before updating prd.json to set `passes: true` for a story:
1. Run ALL verification commands (test suite, typecheck, lint)
2. Paste abbreviated output in progress.txt entry as evidence
3. Only THEN update prd.json

If verification fails: DO NOT mark the story as passing. Instead, note what failed in progress.txt and either fix it (using debugging discipline) or leave the story as `passes: false` for the next iteration.
