#!/bin/bash
# SuperRalph Stop Hook
# Prevents session exit when hook-loop is active

set -euo pipefail

HOOK_INPUT=$(cat)
STATE_FILE=".claude/superralph-state.json"

# No state file -> allow exit
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# Parse state
PHASE=$(jq -r '.phase // "idle"' "$STATE_FILE")
RUN_MODE=$(jq -r '.runMode // ""' "$STATE_FILE")

# Only block if in run phase with hook-loop mode
if [[ "$PHASE" != "run" ]] || [[ "$RUN_MODE" != "hook-loop" ]]; then
  exit 0
fi

# Session isolation
STATE_SESSION=$(jq -r '.sessionId // ""' "$STATE_FILE")
HOOK_SESSION=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""')
if [[ -n "$STATE_SESSION" ]] && [[ "$STATE_SESSION" != "$HOOK_SESSION" ]]; then
  exit 0
fi

# Parse numeric fields
ITERATION=$(jq -r '.iteration // 0' "$STATE_FILE")
MAX_ITERATIONS=$(jq -r '.maxIterations // 0' "$STATE_FILE")

# Validate numeric
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]] || [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "Warning: SuperRalph state file corrupted. Stopping loop." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Check max iterations
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "SuperRalph: Max iterations ($MAX_ITERATIONS) reached."
  rm "$STATE_FILE"
  exit 0
fi

# Get transcript and check for completion
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "Warning: SuperRalph transcript not found. Stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Check for completion promise in last assistant message
if grep -q '"role":"assistant"' "$TRANSCRIPT_PATH"; then
  LAST_OUTPUT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -n 50 | jq -rs 'map(.message.content[]? | select(.type == "text") | .text) | last // ""' 2>/dev/null || echo "")

  PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g' 2>/dev/null || echo "")

  if [[ "$PROMISE_TEXT" == "COMPLETE" ]]; then
    echo "SuperRalph: All stories complete!"
    rm "$STATE_FILE"
    exit 0
  fi
fi

# Not complete -> continue loop
NEXT_ITERATION=$((ITERATION + 1))

# Update iteration in state file
jq ".iteration = $NEXT_ITERATION" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

# ── Build discipline-enriched re-entry prompt ──────────────────
# Derive plugin directory from CLAUDE_PLUGIN_ROOT (set by hooks.json)
# or fall back to relative path from this script's location
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DISCIPLINE_DIR="$PLUGIN_DIR/disciplines"

# Read discipline files if available, otherwise use inline summary
read_discipline() {
  local file="$1"
  local fallback="$2"
  if [[ -f "$file" ]]; then
    cat "$file"
  else
    echo "$fallback"
  fi
}

TDD_CONTENT=$(read_discipline "$DISCIPLINE_DIR/tdd.md" \
  "Write a failing test FIRST, then implement minimal code to pass. Code before test = delete and restart.")

VERIFICATION_CONTENT=$(read_discipline "$DISCIPLINE_DIR/verification.md" \
  "Run all checks (tests, typecheck). Paste evidence. No claims without proof.")

REVIEW_CONTENT=$(read_discipline "$DISCIPLINE_DIR/two-stage-review.md" \
  "Check spec compliance first (nothing missing, nothing extra), then code quality.")

DEBUGGING_CONTENT=$(read_discipline "$DISCIPLINE_DIR/debugging.md" \
  "4 phases: root cause -> pattern analysis -> hypothesis -> implementation. No guessing.")

# Conditionally include web discipline
WEB_CONTENT=""
WEB_PROJECT=$(jq -r '.webProject // false' "$STATE_FILE" 2>/dev/null || echo "false")
if [[ "$WEB_PROJECT" == "true" ]]; then
  WEB_CONTENT=$(read_discipline "$DISCIPLINE_DIR/web-enhance.md" "")
fi

# Get design doc path
DESIGN_DOC=$(jq -r '.designDoc // "N/A"' "$STATE_FILE" 2>/dev/null || echo "N/A")

# Build the comprehensive prompt
PROMPT="Continue working on the current feature. Read tasks/prd.json, find the next story where passes is false, and implement it.

Read tasks/progress.txt (check Codebase Patterns section first) and the design doc at $DESIGN_DOC for context.

## TDD Discipline

$TDD_CONTENT

## Verification Discipline

$VERIFICATION_CONTENT

## Two-Stage Review Discipline

$REVIEW_CONTENT

## Debugging Discipline (activate when tests/builds fail)

$DEBUGGING_CONTENT"

# Append web discipline if applicable
if [[ -n "$WEB_CONTENT" ]]; then
  PROMPT="$PROMPT

## Web Enhancement Discipline

$WEB_CONTENT"
fi

PROMPT="$PROMPT

## Progress Report
APPEND to tasks/progress.txt after completing the story.

## Stop Condition
When ALL stories have passes: true, output <promise>COMPLETE</promise>."

SYSTEM_MSG="SuperRalph iteration $NEXT_ITERATION | To complete: all stories must pass, then output <promise>COMPLETE</promise>"

jq -n \
  --arg prompt "$PROMPT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
