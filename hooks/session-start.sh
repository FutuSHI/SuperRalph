#!/bin/bash
# SuperRalph Session Start Hook
# Displays status if an active SuperRalph session exists

STATE_FILE=".claude/superralph-state.json"

if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# Read state
PHASE=$(jq -r '.phase // "idle"' "$STATE_FILE" 2>/dev/null || echo "idle")

if [[ "$PHASE" == "idle" ]]; then
  exit 0
fi

FEATURE=$(jq -r '.feature // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
ITERATION=$(jq -r '.iteration // 0' "$STATE_FILE" 2>/dev/null || echo "0")
RUN_MODE=$(jq -r '.runMode // ""' "$STATE_FILE" 2>/dev/null || echo "")

echo "🚀 SuperRalph active session detected"
echo "   Feature: $FEATURE"
echo "   Phase: $PHASE"
if [[ "$PHASE" == "run" ]]; then
  echo "   Mode: $RUN_MODE"
  echo "   Iteration: $ITERATION"
fi
echo ""
