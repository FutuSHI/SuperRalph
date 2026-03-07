# Root Cause Tracing

> Sub-technique of Systematic Debugging — Phase 1 (Root Cause Investigation)

## When to Use

- You see an error but don't know where the bad data originated
- A function receives an invalid argument but you didn't call it directly
- The symptom is far from the cause (e.g., crash in rendering, bug in data layer)

## The Technique: Trace Backward

Start from the error. Work backward through the call stack until you find the **first point** where data becomes invalid.

### Step 1: Identify the Error Location

- What exact line/function produced the error?
- What value was unexpected? (null, wrong type, wrong content)
- What value was expected?

### Step 2: Trace the Data Source

- Where did this value come from? (function argument, state, database, API response)
- Who called this function with this value?
- Trace one level up: where did the CALLER get this value?

### Step 3: Keep Tracing Upstream

Repeat Step 2 at each level:

```
Error at: renderUser(user)        ← user is null
  Called by: loadDashboard()      ← user comes from fetchUser()
  Called by: fetchUser()           ← returns null when API returns 404
  Called by: getUserById(id)       ← id is "undefined" (string, not undefined)
  Called by: router.params.userId  ← route parameter not parsed correctly
  ROOT CAUSE: Route definition missing :userId parameter
```

### Step 4: Verify the Root

Ask yourself:
- Is this the FIRST point where data is wrong?
- If I fix this, does the entire chain of errors resolve?
- Or is there something even further upstream?

**Fix at the root, not at the symptom.** Adding a null check at `renderUser()` masks the bug. Fixing the route definition eliminates it.

## Common Mistakes

| Mistake | Why it's wrong |
|---------|---------------|
| Fixing the symptom | Adds a null check instead of fixing why data is null |
| Stopping too early | Fixed the immediate caller but the real bug is 3 levels up |
| Not verifying the root | Assumed the root without tracing all the way back |
| Tracing forward instead of backward | Trying to predict the error path instead of following the actual error |

## In Ralph Iteration Context

When tracing root causes during a SuperRalph iteration:
1. Log each level of the trace in progress.txt
2. Record the final root cause and the full chain
3. This helps future iterations understand the codebase's data flow
