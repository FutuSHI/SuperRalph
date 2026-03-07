# Defense in Depth

> Sub-technique of Systematic Debugging — Preventive Strategy

## When to Use

- Debugging a problem where invalid data passed through multiple layers undetected
- After fixing a root cause, you want to prevent similar issues from silently propagating
- Designing error handling for a new feature with multiple layers

## The Principle

**Validate at every layer boundary, not just the entry point.**

If only the outermost layer validates input, a bug in any intermediate layer can propagate invalid data all the way to the core — where it causes cryptic errors far from the source.

## The Technique

### 1. Identify Layer Boundaries

Every system has layers. Common boundaries:

```
User Input → API Handler → Service Logic → Database
                ↑              ↑              ↑
            Validate       Validate       Validate
             here           here           here
```

Each arrow is a boundary where data should be checked.

### 2. Add Assertions at Boundaries

At each boundary, assert the assumptions that the next layer depends on:

- **API Handler**: Input types, required fields, format validation
- **Service Logic**: Business rule preconditions, state validity
- **Database Layer**: Schema constraints, foreign key integrity
- **Function Entry**: Parameter types/ranges that the function assumes

### 3. Fail Fast

When an assertion fails:
- **Throw immediately** — don't return a default or continue with bad data
- **Include context** — what was expected, what was received, where in the pipeline
- **Fail close to the source** — the earlier you detect, the easier to debug

### 4. When NOT to Add Defensive Checks

Defense in depth does not mean checking everything everywhere:

- **Don't validate internal calls** between functions in the same module that share the same trust boundary
- **Don't re-validate** what was already validated at the system boundary (unless data was transformed)
- **Don't add checks that can never fail** given the type system or language guarantees
- **Don't add defensive checks in hot paths** where performance matters and the data source is trusted

## Rule of Thumb

| Scenario | Add check? |
|----------|-----------|
| Data from user input | Always |
| Data from external API | Always |
| Data from database (could be stale/corrupted) | Usually |
| Data from another module's public API | Usually |
| Data from a private function in the same file | Rarely |
| Data from a pure computation you just performed | No |

## In Ralph Iteration Context

When fixing bugs during a SuperRalph iteration:
1. After finding the root cause, check if defense-in-depth would have caught it earlier
2. If yes, add the appropriate boundary validation as part of the fix
3. Log the defensive check in progress.txt so future iterations understand the pattern
