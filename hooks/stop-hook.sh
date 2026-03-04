#!/bin/bash
# SuperRalph Stop Hook
# Prevents session exit when hook-loop is active

set -euo pipefail

HOOK_INPUT=$(cat)
STATE_FILE=".claude/superralph-state.json"

# No state file → allow exit
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
  echo "⚠️ SuperRalph: State file corrupted. Stopping loop." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Check max iterations
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "🛑 SuperRalph: Max iterations ($MAX_ITERATIONS) reached."
  rm "$STATE_FILE"
  exit 0
fi

# Get transcript and check for completion
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "⚠️ SuperRalph: Transcript not found. Stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Check for completion promise in last assistant message
if grep -q '"role":"assistant"' "$TRANSCRIPT_PATH"; then
  LAST_OUTPUT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -n 50 | jq -rs 'map(.message.content[]? | select(.type == "text") | .text) | last // ""' 2>/dev/null || echo "")

  PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g' 2>/dev/null || echo "")

  if [[ "$PROMISE_TEXT" == "COMPLETE" ]]; then
    echo "✅ SuperRalph: All stories complete!"
    rm "$STATE_FILE"
    exit 0
  fi
fi

# Not complete → continue loop
NEXT_ITERATION=$((ITERATION + 1))

# Update iteration in state file
jq ".iteration = $NEXT_ITERATION" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

# Build re-entry prompt
PROMPT="Continue working on the current feature. Read tasks/prd.json, find the next story where passes is false, and implement it following these disciplines:

1. TDD: Write a failing test FIRST, then implement minimal code to pass. Code before test = delete and restart.
2. Verification: Run all checks (tests, typecheck). Paste evidence. No claims without proof.
3. Two-Stage Review: Check spec compliance first (nothing missing, nothing extra), then code quality.
4. If stuck: Use systematic debugging (4 phases: root cause → pattern analysis → hypothesis → implementation).

When ALL stories have passes: true, output <promise>COMPLETE</promise>."

SYSTEM_MSG="🔄 SuperRalph iteration $NEXT_ITERATION | To complete: all stories must pass, then output <promise>COMPLETE</promise>"

jq -n \
  --arg prompt "$PROMPT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
