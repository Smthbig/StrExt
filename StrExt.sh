#!/bin/bash

# =========================================
# Interactive Folder Structure Generator
# Output: TXT
# =========================================

IGNORE_GIT=true

echo "========================================="
echo " Folder Structure Generator (Bash)"
echo "========================================="

# Ask for folder path
while true; do
  read -rp "Enter folder path: " ROOT_DIR
  if [ -d "$ROOT_DIR" ]; then
    break
  fi
  echo "❌ Directory not found. Try again."
done

# Ask for max depth
read -rp "Max depth? (press Enter for unlimited): " MAX_DEPTH
if [[ -z "$MAX_DEPTH" ]]; then
  MAX_DEPTH=""
elif ! [[ "$MAX_DEPTH" =~ ^[0-9]+$ ]]; then
  echo "Invalid depth. Using unlimited."
  MAX_DEPTH=""
fi

# Ask ignore .git
read -rp "Ignore .git folder? (y/n): " IGNORE_GIT_INPUT
if [[ "$IGNORE_GIT_INPUT" =~ ^[Nn] ]]; then
  IGNORE_GIT=false
fi

# Ask output file
read -rp "Output file name (default: tree_output.txt): " OUTPUT_FILE
OUTPUT_FILE="${OUTPUT_FILE:-tree_output.txt}"

# Clear output
> "$OUTPUT_FILE"

print_tree() {
  local DIR="$1"
  local PREFIX="$2"
  local DEPTH="$3"

  if [ -n "$MAX_DEPTH" ] && [ "$DEPTH" -ge "$MAX_DEPTH" ]; then
    return
  fi

  mapfile -t ITEMS < <(ls -A "$DIR" 2>/dev/null)
  local COUNT=${#ITEMS[@]}
  local INDEX=0

  for ITEM in "${ITEMS[@]}"; do
    INDEX=$((INDEX + 1))

    if $IGNORE_GIT && [ "$ITEM" = ".git" ]; then
      continue
    fi

    local FULL_PATH="$DIR/$ITEM"

    if [ "$INDEX" -eq "$COUNT" ]; then
      CONNECTOR="└── "
      NEW_PREFIX="$PREFIX    "
    else
      CONNECTOR="├── "
      NEW_PREFIX="$PREFIX│   "
    fi

    echo "${PREFIX}${CONNECTOR}${ITEM}" >> "$OUTPUT_FILE"

    if [ -d "$FULL_PATH" ]; then
      print_tree "$FULL_PATH" "$NEW_PREFIX" $((DEPTH + 1))
    fi
  done
}

# Print root
ROOT_NAME=$(basename "$(realpath "$ROOT_DIR")")
echo "$ROOT_NAME/" >> "$OUTPUT_FILE"
print_tree "$ROOT_DIR" "" 0

echo "========================================="
echo "✅ Folder structure generated!"
echo "📄 Saved to: $OUTPUT_FILE"
