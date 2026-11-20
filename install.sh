#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURSOR_SKILLS="${HOME}/.cursor/skills"
KIRO_SKILLS="${HOME}/.kiro/skills"
CLAUDE_SKILLS="${HOME}/.claude/skills"
CODEX_SKILLS="${HOME}/.agents/skills"
LOCAL_BIN="${HOME}/.local/bin"
PROJECT_SKILLS=""
MODE="symlink"
TARGET="cursor"
SKIP_BIN=0

for arg in "$@"; do
  case "$arg" in
    --copy) MODE="copy" ;;
    --kiro) TARGET="kiro"; MODE="copy" ;;
    --claude) TARGET="claude"; MODE="copy" ;;
    --codex) TARGET="codex"; MODE="copy" ;;
    --project)
      TARGET="project"
      PROJECT_SKILLS="${PWD}/.cursor/skills"
      MODE="copy"
      ;;
    --no-bin) SKIP_BIN=1 ;;
    --help|-h)
      echo "Usage: ./install.sh [--copy] [--project] [--kiro] [--claude] [--codex] [--no-bin]"
      echo "  --no-bin  Skip bin/ CLI install when bin/<name> exists"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

SKILLS=(scalyr-dataset)

install_skills() {
  local skills_dir="$1"
  mkdir -p "$skills_dir"
  for skill in "${SKILLS[@]}"; do
    local src="${SCRIPT_DIR}/${skill}"
    local dest="${skills_dir}/${skill}"
    if [[ ! -d "$src" ]]; then
      echo "Missing: $src" >&2
      exit 1
    fi
    rm -rf "$dest"
    if [[ "$MODE" == "copy" ]]; then
      cp -R "$src" "$dest"
      echo "Copied  $skill -> $dest"
    else
      ln -sfn "$src" "$dest"
      echo "Linked  $skill -> $dest"
    fi
  done
}

install_bin_if_present() {
  local src="${SCRIPT_DIR}/bin/scalyr-dataset"
  local dest="${LOCAL_BIN}/scalyr-dataset"
  if [[ ! -f "$src" ]]; then
    return 0
  fi
  if [[ "$SKIP_BIN" -eq 1 || "$TARGET" == "project" ]]; then
    return 0
  fi
  chmod +x "$src"
  mkdir -p "$LOCAL_BIN"
  ln -sfn "$src" "$dest"
  echo "Linked  CLI -> $dest"
}

case "$TARGET" in
  claude) install_skills "$CLAUDE_SKILLS" ;;
  codex)  install_skills "$CODEX_SKILLS" ;;
  kiro)   install_skills "$KIRO_SKILLS" ;;
  project) install_skills "$PROJECT_SKILLS" ;;
  *)      install_skills "$CURSOR_SKILLS" ;;
esac

install_bin_if_present

echo "Done. Restart the agent or start a new chat."
