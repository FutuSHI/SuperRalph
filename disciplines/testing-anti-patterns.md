# Testing Anti-Patterns

> Reference for the TDD Discipline — patterns to avoid when writing tests.

## Anti-Pattern 1: Testing Mock Behavior Instead of Real Behavior

**Description:** Your test mocks a dependency and then asserts that the mock was called correctly. The test passes, but you've only proven that your mock works — not that your code integrates correctly with the real dependency.

**Why it's harmful:** The mock can return values the real dependency never would. Your test gives false confidence while the actual integration is broken.

**What to do instead:** Use real dependencies when feasible (in-memory databases, test servers). When you must mock, assert on the OUTCOME of your code, not on how it called the mock. Mock at the boundary, not in the middle.

## Anti-Pattern 2: Test-Only Methods in Production Code

**Description:** You add a public method to a class purely so your test can inspect internal state. Examples: `getInternalState()`, `_testHelper()`, `resetForTesting()`.

**Why it's harmful:** Production code should not know about tests. These methods expand the public API surface, create maintenance burden, and can be accidentally used in production paths.

**What to do instead:** Test through the public API. If you can't observe the behavior through public methods, the behavior may not matter. If it does matter, refactor so the behavior is observable through normal interfaces.

## Anti-Pattern 3: Mocking Without Understanding the Dependency

**Description:** You mock a dependency without reading its actual behavior. Your mock returns plausible-looking data that doesn't match the real dependency's contract.

**Why it's harmful:** Your test passes against a fantasy version of the dependency. When the real dependency behaves differently (error formats, edge cases, null handling), production breaks.

**What to do instead:** Read the dependency's documentation and source code before mocking. Verify your mock's return values match the real contract. Consider using the dependency's own test fixtures if available.

## Anti-Pattern 4: Incomplete Mocks That Hide Bugs

**Description:** You mock a dependency but only implement the "happy path" behavior. Your mock silently accepts any input and returns a success response, masking validation errors or edge cases.

**Why it's harmful:** Bugs that would surface with the real dependency are invisible. The code ships with untested error paths.

**What to do instead:** If mocking, implement realistic error scenarios too. Test what happens when the dependency returns errors, timeouts, or unexpected data. At minimum, make the mock reject obviously invalid inputs.

## Anti-Pattern 5: Testing Implementation Details Instead of Behavior

**Description:** Your test asserts on internal implementation details (private method calls, internal data structures, specific SQL queries) rather than observable behavior.

**Why it's harmful:** The test breaks every time you refactor, even when behavior is preserved. This makes tests a maintenance burden rather than a safety net.

**What to do instead:** Test the WHAT, not the HOW. Assert on: return values, state changes visible through public API, side effects (files created, messages sent), error messages. A good test should still pass after a refactor that preserves behavior.

## Quick Reference

| Anti-Pattern | Test smells |
|-------------|------------|
| Testing mocks | `verify(mock).wasCalledWith(...)` is the primary assertion |
| Test-only methods | Production code has methods only called from tests |
| Blind mocking | Mock returns hardcoded values without checking real API |
| Incomplete mocks | Mock only handles happy path, never returns errors |
| Implementation testing | Test breaks on refactor even when behavior unchanged |
