#!/usr/bin/env bash
# install.sh — Install WormScript AI Skills
# Usage: bash install.sh [--tool <tool>] [--skill <skill>] [--project-dir <path>]
#
# Tools:  claude-code (default), cursor, copilot, windsurf, all
# Skills: wrm-data-builder, wrm, all (default: all)

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills"
TOOL="claude-code"
SKILL="all"
PROJECT_DIR="$(pwd)"

while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)        TOOL="$2";        shift 2 ;;
    --skill)       SKILL="$2";       shift 2 ;;
    --project-dir) PROJECT_DIR="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "WormScript AI Skills Installer"
echo "==============================="
echo "Tool:        $TOOL"
echo "Skill:       $SKILL"
echo "Repo:        $REPO_DIR"

# ── Helpers ────────────────────────────────────────────────────────────────────

install_claude_skill() {
  local skill_name="$1"
  if [[ ! -d "$REPO_DIR/$skill_name" ]]; then
    echo "  [skip] Skill '$skill_name' not found in repo"
    return
  fi
  mkdir -p "$SKILLS_DIR"
  cp -r "$REPO_DIR/$skill_name" "$SKILLS_DIR/"
  echo "  Copied $skill_name → $SKILLS_DIR/$skill_name"
}

install_cursor_skill() {
  local skill_name="$1"
  local adapter="$REPO_DIR/$skill_name/adapters/cursor.mdc"
  if [[ ! -f "$adapter" ]]; then
    echo "  [skip] No cursor adapter for '$skill_name'"
    return
  fi
  mkdir -p "$PROJECT_DIR/.cursor/rules"
  cp "$adapter" "$PROJECT_DIR/.cursor/rules/$skill_name.mdc"
  echo "  Copied cursor.mdc → $PROJECT_DIR/.cursor/rules/$skill_name.mdc"
}

install_copilot_skill() {
  local skill_name="$1"
  local adapter="$REPO_DIR/$skill_name/adapters/copilot-instructions.md"
  if [[ ! -f "$adapter" ]]; then
    echo "  [skip] No copilot adapter for '$skill_name'"
    return
  fi
  mkdir -p "$PROJECT_DIR/.github"
  # Append to existing file if present, otherwise create
  if [[ -f "$PROJECT_DIR/.github/copilot-instructions.md" ]]; then
    echo "" >> "$PROJECT_DIR/.github/copilot-instructions.md"
    echo "---" >> "$PROJECT_DIR/.github/copilot-instructions.md"
    echo "" >> "$PROJECT_DIR/.github/copilot-instructions.md"
    cat "$adapter" >> "$PROJECT_DIR/.github/copilot-instructions.md"
    echo "  Appended $skill_name → $PROJECT_DIR/.github/copilot-instructions.md"
  else
    cp "$adapter" "$PROJECT_DIR/.github/copilot-instructions.md"
    echo "  Copied copilot-instructions.md → $PROJECT_DIR/.github/copilot-instructions.md"
  fi
}

install_windsurf_skill() {
  local skill_name="$1"
  local adapter="$REPO_DIR/$skill_name/adapters/windsurf.rules"
  if [[ ! -f "$adapter" ]]; then
    echo "  [skip] No windsurf adapter for '$skill_name'"
    return
  fi
  if [[ -f "$PROJECT_DIR/.windsurfrules" ]]; then
    echo "" >> "$PROJECT_DIR/.windsurfrules"
    echo "---" >> "$PROJECT_DIR/.windsurfrules"
    echo "" >> "$PROJECT_DIR/.windsurfrules"
    cat "$adapter" >> "$PROJECT_DIR/.windsurfrules"
    echo "  Appended $skill_name → $PROJECT_DIR/.windsurfrules"
  else
    cp "$adapter" "$PROJECT_DIR/.windsurfrules"
    echo "  Copied windsurf.rules → $PROJECT_DIR/.windsurfrules"
  fi
}

# ── Skill list ─────────────────────────────────────────────────────────────────

ALL_SKILLS=("wrm-tool" "wrm-data-builder")

get_skills() {
  if [[ "$SKILL" == "all" ]]; then
    echo "${ALL_SKILLS[@]}"
  else
    echo "$SKILL"
  fi
}

# ── Tool installers ─────────────────────────────────────────────────────────────

install_claude_code() {
  echo ""
  echo "Installing for Claude Code..."
  for s in $(get_skills); do
    install_claude_skill "$s"
  done
  echo ""
  echo "Done. Restart Claude Code to load the skills."
}

install_cursor() {
  echo ""
  echo "Installing for Cursor (project: $PROJECT_DIR)..."
  for s in $(get_skills); do
    install_cursor_skill "$s"
  done
  echo ""
  echo "Done. Rules activate automatically in Cursor."
}

install_copilot() {
  echo ""
  echo "Installing for GitHub Copilot (project: $PROJECT_DIR)..."
  for s in $(get_skills); do
    install_copilot_skill "$s"
  done
  echo ""
  echo "Done. Copilot loads instructions automatically for this project."
}

install_windsurf() {
  echo ""
  echo "Installing for Windsurf (project: $PROJECT_DIR)..."
  for s in $(get_skills); do
    install_windsurf_skill "$s"
  done
  echo ""
  echo "Done. Windsurf loads rules automatically."
}

# ── Dispatch ───────────────────────────────────────────────────────────────────

case "$TOOL" in
  claude-code) install_claude_code ;;
  cursor)      install_cursor ;;
  copilot)     install_copilot ;;
  windsurf)    install_windsurf ;;
  all)
    install_claude_code
    install_cursor
    install_copilot
    install_windsurf
    ;;
  *)
    echo "Unknown tool: $TOOL"
    echo "Valid options: claude-code, cursor, copilot, windsurf, all"
    exit 1
    ;;
esac
