#!/usr/bin/env bash
set -e

# ──────────────────────────────────────────────────────────────
# SuperRalph Execution Engine
#
# Runs Claude Code in a loop, injecting discipline rules into
# each iteration's instructions. Each iteration gets a fresh
# context window with the full discipline set.
# ──────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# ── Defaults ──────────────────────────────────────────────────
MAX_ITERATIONS=20
PROJECT_DIR="$(pwd)"
FEATURE_NAME=""
INSTRUCTIONS_FILE=""
WEB_PROJECT=false

# ── Usage ─────────────────────────────────────────────────────
usage() {
  cat <<'USAGE'
Usage: ralph.sh [OPTIONS] [FEATURE_NAME]

Run SuperRalph: an autonomous Claude Code loop with discipline injection.

Options:
  --max-iterations N   Maximum loop iterations (default: 20)
  --project-dir PATH   Path to the project directory (default: current directory)
  --help               Show this help message and exit

Arguments:
  FEATURE_NAME         Optional feature name used in logging and progress tracking

Examples:
  ralph.sh
  ralph.sh --max-iterations 10 my-feature
  ralph.sh --project-dir /path/to/project --max-iterations 5 auth-system
USAGE
  exit 0
}

# ── Argument Parsing ──────────────────────────────────────────
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --max-iterations)
        shift
        MAX_ITERATIONS="$1"
        ;;
      --project-dir)
        shift
        PROJECT_DIR="$1"
        ;;
      --help)
        usage
        ;;
      -*)
        echo "Error: Unknown option '$1'"
        echo "Run 'ralph.sh --help' for usage."
        exit 1
        ;;
      *)
        FEATURE_NAME="$1"
        ;;
    esac
    shift
  done
}

# ── Locate Project Files ─────────────────────────────────────
locate_files() {
  local prd="$PROJECT_DIR/tasks/prd.json"

  if [ ! -f "$prd" ]; then
    echo "Error: PRD not found at $prd"
    echo "Create tasks/prd.json before running SuperRalph."
    exit 1
  fi

  if [ ! -f "$PROJECT_DIR/tasks/progress.txt" ]; then
    initialize_progress
  fi
}

# ── Initialize progress.txt ──────────────────────────────────
initialize_progress() {
  local template="$PLUGIN_DIR/templates/progress.txt.template"
  local progress="$PROJECT_DIR/tasks/progress.txt"
  local prd="$PROJECT_DIR/tasks/prd.json"

  mkdir -p "$PROJECT_DIR/tasks"

  local date_str
  date_str="$(date '+%Y-%m-%d %H:%M')"

  local feature
  if [ -n "$FEATURE_NAME" ]; then
    feature="$FEATURE_NAME"
  else
    feature="$(jq -r '.project // "unknown"' "$prd" 2>/dev/null || echo "unknown")"
  fi

  local design_doc
  design_doc="$(jq -r '.designDoc // "N/A"' "$prd" 2>/dev/null || echo "N/A")"

  if [ -f "$template" ]; then
    sed -e "s|{DATE}|$date_str|g" \
        -e "s|{FEATURE}|$feature|g" \
        -e "s|{DESIGN_DOC}|$design_doc|g" \
        "$template" > "$progress"
  else
    cat > "$progress" <<EOF
# SuperRalph Progress Log
Started: $date_str
Feature: $feature
Design Doc: $design_doc
---

## Codebase Patterns
(Consolidate reusable patterns here as they are discovered)

---
EOF
  fi

  echo "Initialized progress.txt"
}

# ── Archive Previous Run ─────────────────────────────────────
archive_if_branch_changed() {
  local prd="$PROJECT_DIR/tasks/prd.json"
  local last_branch_file="$PROJECT_DIR/.superralph/.last-branch"
  local current_branch
  current_branch="$(jq -r '.branchName // ""' "$prd" 2>/dev/null || echo "")"

  if [ -z "$current_branch" ]; then
    return
  fi

  if [ -f "$last_branch_file" ]; then
    local last_branch
    last_branch="$(cat "$last_branch_file")"

    if [ "$current_branch" != "$last_branch" ]; then
      echo "Branch changed: $last_branch -> $current_branch"
      echo "Archiving previous run..."

      local date_prefix
      date_prefix="$(date '+%Y-%m-%d')"
      local archive_name="${date_prefix}-${FEATURE_NAME:-$(echo "$last_branch" | sed 's|.*/||')}"
      local archive_dir="$PROJECT_DIR/archive/$archive_name"

      mkdir -p "$archive_dir"

      # Copy PRD
      cp "$prd" "$archive_dir/prd.json"

      # Copy progress
      if [ -f "$PROJECT_DIR/tasks/progress.txt" ]; then
        cp "$PROJECT_DIR/tasks/progress.txt" "$archive_dir/progress.txt"
      fi

      # Copy design doc
      local design_doc
      design_doc="$(jq -r '.designDoc // ""' "$prd" 2>/dev/null || echo "")"
      if [ -n "$design_doc" ] && [ -f "$PROJECT_DIR/$design_doc" ]; then
        local design_doc_dir
        design_doc_dir="$(dirname "$archive_dir/$design_doc")"
        mkdir -p "$design_doc_dir"
        cp "$PROJECT_DIR/$design_doc" "$archive_dir/$design_doc"
      fi

      # Reset progress.txt with fresh template
      initialize_progress
      echo "Archive saved to $archive_dir"
    fi
  fi
}

# ── Track Current Branch ──────────────────────────────────────
track_branch() {
  local prd="$PROJECT_DIR/tasks/prd.json"
  local current_branch
  current_branch="$(jq -r '.branchName // ""' "$prd" 2>/dev/null || echo "")"

  if [ -n "$current_branch" ]; then
    mkdir -p "$PROJECT_DIR/.superralph"
    echo "$current_branch" > "$PROJECT_DIR/.superralph/.last-branch"
  fi
}

# ── Detect Web Project ────────────────────────────────────────
detect_web_project() {
  WEB_PROJECT=false
  local pkg="$PROJECT_DIR/package.json"

  if [ -f "$pkg" ]; then
    local web_frameworks="react|next|vue|nuxt|angular|svelte|solid-js|astro|remix|gatsby"
    # Check both dependencies and devDependencies
    local all_deps
    all_deps="$(jq -r '(.dependencies // {} | keys[]) , (.devDependencies // {} | keys[])' "$pkg" 2>/dev/null || echo "")"

    if echo "$all_deps" | grep -qE "^($web_frameworks)$"; then
      WEB_PROJECT=true
    fi
  fi
}

# ── Replace Placeholder with File Contents ────────────────────
replace_placeholder() {
  local file="$1"
  local placeholder="$2"
  local content_file="$3"

  if [ -f "$content_file" ]; then
    perl -i -0777 -pe "
      open(my \$fh, '<', '$content_file') or die \"Cannot open $content_file: \$!\";
      my \$content = do { local \$/; <\$fh> };
      close(\$fh);
      s/\\Q$placeholder\\E/\$content/g;
    " "$file"
  else
    echo "Warning: Discipline file not found: $content_file"
  fi
}

# ── Build Per-Iteration Instructions ──────────────────────────
build_instructions() {
  local template="$PLUGIN_DIR/templates/CLAUDE.md.template"

  if [ ! -f "$template" ]; then
    echo "Error: Template not found at $template"
    exit 1
  fi

  cp "$template" "$INSTRUCTIONS_FILE"

  # Replace discipline placeholders with file contents
  replace_placeholder "$INSTRUCTIONS_FILE" "{TDD_DISCIPLINE}" "$PLUGIN_DIR/disciplines/tdd.md"
  replace_placeholder "$INSTRUCTIONS_FILE" "{VERIFICATION_DISCIPLINE}" "$PLUGIN_DIR/disciplines/verification.md"
  replace_placeholder "$INSTRUCTIONS_FILE" "{REVIEW_DISCIPLINE}" "$PLUGIN_DIR/disciplines/two-stage-review.md"
  replace_placeholder "$INSTRUCTIONS_FILE" "{DEBUGGING_DISCIPLINE}" "$PLUGIN_DIR/disciplines/debugging.md"

  # Web discipline: inject or remove
  if [ "$WEB_PROJECT" = true ]; then
    # Build web discipline content with heading
    local web_file="$PLUGIN_DIR/disciplines/web-enhance.md"
    if [ -f "$web_file" ]; then
      # Create a temporary file with the heading + web discipline content
      local web_tmp
      web_tmp="$(mktemp)"
      printf '### Web Enhancement Discipline\n\n' > "$web_tmp"
      cat "$web_file" >> "$web_tmp"
      replace_placeholder "$INSTRUCTIONS_FILE" "{WEB_DISCIPLINE}" "$web_tmp"
      rm -f "$web_tmp"
    else
      echo "Warning: Web discipline file not found: $web_file"
      perl -i -0777 -pe 's/\{WEB_DISCIPLINE\}//g' "$INSTRUCTIONS_FILE"
    fi
  else
    perl -i -0777 -pe 's/\{WEB_DISCIPLINE\}//g' "$INSTRUCTIONS_FILE"
  fi

  # Replace design doc path
  local design_doc
  design_doc="$(jq -r '.designDoc // "N/A"' "$PROJECT_DIR/tasks/prd.json" 2>/dev/null || echo "N/A")"
  sed -i '' "s|{DESIGN_DOC}|$design_doc|g" "$INSTRUCTIONS_FILE"
}

# ── Main ──────────────────────────────────────────────────────
main() {
  parse_args "$@"

  # Resolve project dir to absolute path
  PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

  echo "==============================================================="
  echo "  SuperRalph Execution Engine"
  echo "==============================================================="
  echo "  Project:        $PROJECT_DIR"
  echo "  Max iterations: $MAX_ITERATIONS"
  echo "  Feature:        ${FEATURE_NAME:-"(auto)"}"
  echo "  Plugin:         $PLUGIN_DIR"
  echo "==============================================================="

  # Locate and validate project files
  locate_files

  # Archive if branch changed since last run
  archive_if_branch_changed

  # Track the current branch
  track_branch

  # Detect web project
  detect_web_project
  echo "  Web project:    $WEB_PROJECT"
  echo ""

  # Create temp file for assembled instructions
  INSTRUCTIONS_FILE="$(mktemp "${TMPDIR:-/tmp}/superralph-instructions.XXXXXX")"

  # Ensure cleanup on exit
  trap 'rm -f "$INSTRUCTIONS_FILE"' EXIT

  # ── Main Loop ─────────────────────────────────────────────
  for i in $(seq 1 "$MAX_ITERATIONS"); do
    echo ""
    echo "==============================================================="
    echo "  SuperRalph Iteration $i of $MAX_ITERATIONS"
    echo "==============================================================="

    # Rebuild instructions each iteration (disciplines may have been updated)
    build_instructions

    # Run Claude Code with assembled instructions
    OUTPUT=$(claude --dangerously-skip-permissions --print < "$INSTRUCTIONS_FILE" 2>&1 | tee /dev/stderr) || true

    # Check for completion signal
    if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
      echo ""
      echo "==============================================================="
      echo "  SuperRalph completed all stories!"
      echo "  Completed at iteration $i of $MAX_ITERATIONS"
      echo "==============================================================="
      exit 0
    fi

    echo ""
    echo "Iteration $i complete. Continuing..."
    sleep 2
  done

  # ── Max Iterations Reached ────────────────────────────────
  echo ""
  echo "==============================================================="
  echo "  WARNING: Max iterations ($MAX_ITERATIONS) reached"
  echo "==============================================================="
  echo ""
  echo "  Not all stories are complete. You can:"
  echo "    1. Run again with more iterations:"
  echo "       ralph.sh --max-iterations $((MAX_ITERATIONS + 10)) ${FEATURE_NAME:+$FEATURE_NAME}"
  echo "    2. Run /finish to wrap up the current state"
  echo "    3. Check tasks/progress.txt for what was accomplished"
  echo ""
  exit 1
}

main "$@"
