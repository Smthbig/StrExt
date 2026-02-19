#!/usr/bin/env bash

# =====================================================
# Folder Structure Generator v1
# Stable traversal, correct connectors, production-ready
# =====================================================

set -Eeuo pipefail
IFS=$'\n\t'

# ------------------ Defaults ------------------

IGNORE_GIT=true
IGNORE_HIDDEN=false
MAX_DEPTH=""
OUTPUT_NAME="tree-str.txt"
SAVE_INSIDE=false

# ------------------ UI ------------------

echo "========================================="
echo " Folder Structure Generator v1"
echo "========================================="

# Folder input
while true; do
  read -rp "Enter folder path: " ROOT_DIR
  if [[ -d "$ROOT_DIR" ]]; then
    break
  fi
  echo "Directory not found. Try again."
done

# Depth
read -rp "Max depth? (press Enter for unlimited): " MAX_DEPTH
if [[ -n "$MAX_DEPTH" && ! "$MAX_DEPTH" =~ ^[0-9]+$ ]]; then
  echo "Invalid depth. Using unlimited."
  MAX_DEPTH=""
fi

# Ignore .git
read -rp "Ignore .git folder? (y/n): " input
[[ "$input" =~ ^[Nn] ]] && IGNORE_GIT=false

# Ignore hidden
read -rp "Ignore hidden files/folders? (y/n): " input
[[ "$input" =~ ^[Yy] ]] && IGNORE_HIDDEN=true

# Save inside selected folder
read -rp "Save inside selected folder? (y/n): " input
[[ "$input" =~ ^[Yy] ]] && SAVE_INSIDE=true

# ------------------ Output Setup ------------------

if $SAVE_INSIDE; then
  OUTPUT_FILE="$ROOT_DIR/$OUTPUT_NAME"
else
  OUTPUT_FILE="$OUTPUT_NAME"
fi

# Auto overwrite (safe)
: > "$OUTPUT_FILE"

echo "Generated on: $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# ------------------ Core Logic ------------------

print_tree() {
  local DIR="$1"
  local PREFIX="$2"
  local DEPTH="$3"

  # Depth guard
  if [[ -n "$MAX_DEPTH" && "$DEPTH" -ge "$MAX_DEPTH" ]]; then
    return
  fi

  # Read items (stable logic preserved)
  mapfile -t ALL_ITEMS < <(ls -A "$DIR" 2>/dev/null)

  # 🔴 FIXED: Filter BEFORE counting
  local ITEMS=()
  for ITEM in "${ALL_ITEMS[@]}"; do
    if $IGNORE_GIT && [[ "$ITEM" == ".git" ]]; then
      continue
    fi
    if $IGNORE_HIDDEN && [[ "$ITEM" == .* ]]; then
      continue
    fi
    ITEMS+=("$ITEM")
  done

  local COUNT=${#ITEMS[@]}
  local INDEX=0

  for ITEM in "${ITEMS[@]}"; do
    INDEX=$((INDEX + 1))

    local FULL_PATH="$DIR/$ITEM"

    local CONNECTOR NEW_PREFIX
    if [[ "$INDEX" -eq "$COUNT" ]]; then
      CONNECTOR="└── "
      NEW_PREFIX="${PREFIX}    "
    else
      CONNECTOR="├── "
      NEW_PREFIX="${PREFIX}│   "
    fi

    echo "${PREFIX}${CONNECTOR}${ITEM}" >> "$OUTPUT_FILE"

    if [[ -d "$FULL_PATH" ]]; then
      print_tree "$FULL_PATH" "$NEW_PREFIX" $((DEPTH + 1))
    fi
  done
}

# ------------------ Start ------------------

ROOT_NAME="$(basename "$(cd "$ROOT_DIR" && pwd)")"
echo "${ROOT_NAME}/" >> "$OUTPUT_FILE"
print_tree "$ROOT_DIR" "" 0

echo "========================================="
echo "Structure generated successfully."
echo "Saved to: $OUTPUT_FILE"
