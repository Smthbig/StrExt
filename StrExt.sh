#!/usr/bin/env bash
# ==========================================
# Folder Structure Generator (Production)
# Output: TXT
# ==========================================

set -Eeuo pipefail
IFS=$'\n\t'

# ---------- Defaults ----------
IGNORE_GIT=true
MAX_DEPTH=""
OUTPUT_FILE="tree_output.txt"

# ---------- Utils ----------
die() {
  echo "Error: $*" >&2
  exit 1
}

prompt_dir() {
  while true; do
    read -rp "Enter folder path: " ROOT_DIR
    [[ -d "$ROOT_DIR" ]] && break
    echo "Directory does not exist. Try again."
  done
}

prompt_depth() {
  read -rp "Max depth (Enter = unlimited): " MAX_DEPTH
  [[ -z "$MAX_DEPTH" ]] && return
  [[ "$MAX_DEPTH" =~ ^[0-9]+$ ]] || {
    echo "Invalid depth. Using unlimited."
    MAX_DEPTH=""
  }
}

prompt_ignore_git() {
  read -rp "Ignore .git folder? (y/n): " ans
  [[ "$ans" =~ ^[Nn] ]] && IGNORE_GIT=false
}

prompt_output() {
  read -rp "Output file (default: tree_output.txt): " out
  [[ -n "$out" ]] && OUTPUT_FILE="$out"
}

# ---------- Core Logic ----------
print_tree() {
  local dir="$1"
  local prefix="$2"
  local depth="$3"

  [[ -n "$MAX_DEPTH" && "$depth" -ge "$MAX_DEPTH" ]] && return

  local entries=()
  while IFS= read -r -d '' entry; do
    entries+=("$entry")
  done < <(find "$dir" -mindepth 1 -maxdepth 1 -print0 | sort -z)

  local total="${#entries[@]}"
  local index=0

  for entry in "${entries[@]}"; do
    local name
    name="$(basename "$entry")"

    $IGNORE_GIT && [[ "$name" == ".git" ]] && continue

    index=$((index + 1))
    local connector new_prefix

    if [[ "$index" -eq "$total" ]]; then
      connector="└── "
      new_prefix="${prefix}    "
    else
      connector="├── "
      new_prefix="${prefix}│   "
    fi

    echo "${prefix}${connector}${name}" >> "$OUTPUT_FILE"

    [[ -d "$entry" ]] && print_tree "$entry" "$new_prefix" $((depth + 1))
  done
}

# ---------- Main ----------
main() {
  echo "========================================="
  echo " Folder Structure Generator"
  echo "========================================="

  prompt_dir
  prompt_depth
  prompt_ignore_git
  prompt_output

  : > "$OUTPUT_FILE"

  local root
  root="$(basename "$(cd "$ROOT_DIR" && pwd)")"

  echo "${root}/" >> "$OUTPUT_FILE"
  print_tree "$ROOT_DIR" "" 0

  echo "========================================="
  echo "Output written to: $OUTPUT_FILE"
}

main "$@"
