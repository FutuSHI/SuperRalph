# TDD Discipline

## The Iron Law

**NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.**

If you wrote production code before writing a test for it: **DELETE the production code. Start over with the test.**

No exceptions. No "keeping as reference." No "adapting while writing tests." Delete means delete.

## The RED-GREEN-REFACTOR Cycle

For each acceptance criterion in the current story:

### 1. RED — Write a Failing Test

- Write ONE minimal test that describes what should happen
- Name the test after the behavior, not the implementation
- Assert on real behavior — avoid excessive mocking
- **Run the test. Confirm it FAILS.**
- Confirm it fails because the feature is missing, not because of typos or setup errors

### 2. GREEN — Write Minimal Code

- Write the SIMPLEST code that makes the test pass
- Do NOT add features beyond what the test requires
- Do NOT refactor yet
- Do NOT "improve" other code while here
- **Run the test. Confirm it PASSES.**
- Confirm all other tests still pass

### 3. REFACTOR — Clean Up (Only After Green)

- Remove duplication
- Improve naming
- Extract helpers if needed
- **Keep all tests green throughout**
- Do NOT add new behavior during refactor

### 4. REPEAT

- Next acceptance criterion leads to the next failing test leads to the next cycle

## Per-Story TDD Rhythm

1. Read the story's acceptance criteria
2. For criterion 1: Write failing test → verify RED → implement → verify GREEN → refactor
3. For criterion 2: Write failing test → verify RED → implement → verify GREEN → refactor
4. ... repeat for all criteria
5. All criteria verified → commit

## Anti-Rationalization Table

| Rationalization | Reality |
|----------------|---------|
| "Too simple to test" | Simple code breaks. Takes 30 seconds to test. Do it. |
| "I'll test after" | Tests that pass immediately on first run prove nothing. They answer "what does this do?" not "what should this do?" |
| "Already manually tested" | Ad-hoc testing ≠ systematic testing. No re-run capability. No regression protection. |
| "TDD will slow me down" | TDD is faster than debugging. You're an autonomous agent with limited iterations. Wasting an iteration on debugging is expensive. |
| "This is different because..." | No. It's not different. Delete code. Start over with test. |
| "I already spent time on this code" | Sunk cost fallacy. Keeping unverified code is technical debt that will cost MORE iterations later. |
| "Just this once" | There is no "just this once." Every violation compounds. |
| "The test is obvious" | If it's obvious, it takes 30 seconds. Write it. |
| "I'll add the test in the same commit" | Writing test after code ≠ TDD. The test must fail first to prove it tests the right thing. |

## Red Flags — STOP and Restart

If any of these happen, you have violated TDD. Stop. Delete the production code. Start over with the test:

- You wrote production code before its test
- A new test passes immediately on first run (without you writing new code)
- You can't explain why a test failed
- You're adding tests "to cover" already-written code
- You're rationalizing why this case is different

## Exceptions

These cases MAY skip TDD (but note the skip in your progress report):

- Pure configuration file changes (no logic)
- Auto-generated code (migrations, scaffolds)
- Documentation-only changes

For anything with logic: TDD. No exceptions.

## Testing Anti-Patterns

See the Testing Anti-Patterns section below for common mistakes that undermine test value:
- Testing mock behavior instead of real behavior
- Test-only methods in production code
- Mocking without understanding the dependency
- Incomplete mocks that hide bugs
- Testing implementation details instead of behavior
