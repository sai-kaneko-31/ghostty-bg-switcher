#!/usr/bin/env bats

# Tests for generator.zsh
# Image generation via Gemini CLI

setup() {
  TEST_DIR="$(mktemp -d)"
  SAVE_DIR="$TEST_DIR/generated"

  LIB_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../lib" && pwd)"
  source "$LIB_DIR/generator.zsh"
}

teardown() {
  rm -rf "$TEST_DIR"
  if [ -n "$ORIGINAL_PATH" ]; then
    export PATH="$ORIGINAL_PATH"
  fi
}

# --- gbsw_generate_image ---

@test "gbsw_generate_image: error when gemini command not found" {
  ORIGINAL_PATH="$PATH"
  export PATH="/usr/bin:/bin"
  run gbsw_generate_image "a beautiful sunset" "$TEST_DIR/output.png"
  [ "$status" -eq 1 ]
  [[ "$output" == *"gemini"* ]]
}

@test "gbsw_generate_image: auto-create output directory if missing" {
  mkdir -p "$TEST_DIR/bin"
  cat > "$TEST_DIR/bin/gemini" <<'MOCK'
#!/bin/bash
for arg in "$@"; do
  case "$prev" in
    --output|-o) echo "dummy" > "$arg"; output_set=1 ;;
  esac
  prev="$arg"
done
for i in "$@"; do
  if [[ "$i" == --save=* ]]; then
    dir="${i#--save=}"
    mkdir -p "$dir"
    echo "dummy" > "$dir/generated.png"
  fi
done
MOCK
  chmod +x "$TEST_DIR/bin/gemini"
  ORIGINAL_PATH="$PATH"
  export PATH="$TEST_DIR/bin:$PATH"

  run gbsw_generate_image "test prompt" "$SAVE_DIR/output.png"
  [ -d "$SAVE_DIR" ]
}

@test "gbsw_generate_image: error when prompt is empty" {
  run gbsw_generate_image "" "$TEST_DIR/output.png"
  [ "$status" -eq 1 ]
}

@test "gbsw_generate_image: outputs image path to stdout on success" {
  mkdir -p "$TEST_DIR/bin"
  cat > "$TEST_DIR/bin/gemini" <<'MOCK'
#!/bin/bash
save_dir=""
prev=""
for arg in "$@"; do
  if [[ "$prev" == "--save" ]]; then
    save_dir="$arg"
  fi
  prev="$arg"
done
if [[ -n "$save_dir" ]]; then
  mkdir -p "$save_dir"
  echo "dummy" > "$save_dir/generated_image.png"
fi
exit 0
MOCK
  chmod +x "$TEST_DIR/bin/gemini"
  ORIGINAL_PATH="$PATH"
  export PATH="$TEST_DIR/bin:$PATH"

  mkdir -p "$SAVE_DIR"
  run gbsw_generate_image "a cat in space" "$SAVE_DIR/output.png"
  [ "$status" -eq 0 ]
  [[ "$output" == *"$SAVE_DIR"* ]]
}
