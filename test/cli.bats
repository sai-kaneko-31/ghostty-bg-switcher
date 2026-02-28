#!/usr/bin/env bats

# CLI integration tests
# Tests for bin/ghostty-bg-switcher subcommands

setup() {
  TEST_DIR="$(mktemp -d)"
  TEST_CONFIG="$TEST_DIR/config"
  IMAGE_DIR="$TEST_DIR/images"
  LOCK_DIR="$TEST_DIR/lock"

  cat > "$TEST_CONFIG" <<'EOF'
font-size = 14
background-image = /existing/bg.png
background-image-opacity = 0.5
background-image-fit = contain
EOF

  mkdir -p "$IMAGE_DIR"
  touch "$IMAGE_DIR/a.png"
  touch "$IMAGE_DIR/b.jpg"
  touch "$IMAGE_DIR/c.jpeg"

  export GBSW_CONFIG_PATH="$TEST_CONFIG"
  export GBSW_NO_RELOAD=1
  export GBSW_LOCK_DIR="$LOCK_DIR"

  BIN="$(cd "$(dirname "$BATS_TEST_FILENAME")/../bin" && pwd)/ghostty-bg-switcher"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# --- help ---

@test "no args: show usage and exit code 2" {
  run "$BIN"
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage"* ]] || [[ "$output" == *"Usage"* ]]
}

@test "--help: show help" {
  run "$BIN" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"set"* ]]
  [[ "$output" == *"random"* ]]
  [[ "$output" == *"list"* ]]
  [[ "$output" == *"clear"* ]]
  [[ "$output" == *"current"* ]]
  [[ "$output" == *"generate"* ]]
}

# --- set ---

@test "set: can set an image" {
  run "$BIN" set "$IMAGE_DIR/a.png"
  [ "$status" -eq 0 ]
  run grep "^background-image" "$TEST_CONFIG"
  [[ "$output" == *"$IMAGE_DIR/a.png"* ]]
}

@test "set: error on nonexistent file" {
  run "$BIN" set "/no/such/file.png"
  [ "$status" -eq 1 ]
}

@test "set: error on unsupported format" {
  touch "$TEST_DIR/image.gif"
  run "$BIN" set "$TEST_DIR/image.gif"
  [ "$status" -eq 1 ]
}

@test "set: error with no args" {
  run "$BIN" set
  [ "$status" -eq 2 ]
}

@test "set --opacity: set opacity simultaneously" {
  run "$BIN" set "$IMAGE_DIR/a.png" --opacity 0.3
  [ "$status" -eq 0 ]
  run grep "^background-image-opacity" "$TEST_CONFIG"
  [[ "$output" == *"0.3"* ]]
}

@test "set --fit: set fit mode simultaneously" {
  run "$BIN" set "$IMAGE_DIR/a.png" --fit cover
  [ "$status" -eq 0 ]
  run grep "^background-image-fit" "$TEST_CONFIG"
  [[ "$output" == *"cover"* ]]
}

# --- random ---

@test "random: set random image from directory" {
  run "$BIN" random "$IMAGE_DIR"
  [ "$status" -eq 0 ]
  run grep "^background-image" "$TEST_CONFIG"
  [[ "$output" == *"$IMAGE_DIR/"* ]]
}

@test "random: error on nonexistent directory" {
  run "$BIN" random "/no/such/dir"
  [ "$status" -eq 1 ]
}

@test "random: error with no args" {
  run "$BIN" random
  [ "$status" -eq 2 ]
}

# --- list ---

@test "list: show image file list" {
  run "$BIN" list "$IMAGE_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"a.png"* ]]
  [[ "$output" == *"b.jpg"* ]]
  [[ "$output" == *"c.jpeg"* ]]
}

@test "list: error on nonexistent directory" {
  run "$BIN" list "/no/such/dir"
  [ "$status" -eq 1 ]
}

# --- clear ---

@test "clear: remove background image setting" {
  run "$BIN" clear
  [ "$status" -eq 0 ]
  run grep "^background-image " "$TEST_CONFIG"
  [ "$status" -eq 1 ]
}

@test "clear: also remove background-image-opacity etc" {
  run "$BIN" clear
  [ "$status" -eq 0 ]
  run grep "^background-image-opacity" "$TEST_CONFIG"
  [ "$status" -eq 1 ]
  run grep "^background-image-fit" "$TEST_CONFIG"
  [ "$status" -eq 1 ]
}

@test "clear: preserve other settings" {
  run "$BIN" clear
  run grep "^font-size" "$TEST_CONFIG"
  [ "$status" -eq 0 ]
}

# --- current ---

@test "current: show current background image path" {
  run "$BIN" current
  [ "$status" -eq 0 ]
  [ "$output" = "/existing/bg.png" ]
}

@test "current: show message when no background image set" {
  grep -v '^background-image ' "$TEST_CONFIG" > "${TEST_CONFIG}.tmp" && mv "${TEST_CONFIG}.tmp" "$TEST_CONFIG"
  run "$BIN" current
  [ "$status" -eq 0 ]
  [[ "$output" != "" ]]
}

# --- generate ---

@test "generate: error with no prompt" {
  run "$BIN" generate
  [ "$status" -eq 2 ]
}

# --- unknown subcommand ---

@test "unknown subcommand: error" {
  run "$BIN" unknown_command
  [ "$status" -eq 2 ]
}

# --- --config option ---

@test "--config: use specified config file path" {
  OTHER_CONFIG="$TEST_DIR/other_config"
  echo "background-image = /other/image.png" > "$OTHER_CONFIG"
  unset GBSW_CONFIG_PATH
  run "$BIN" current --config "$OTHER_CONFIG"
  [ "$status" -eq 0 ]
  [ "$output" = "/other/image.png" ]
}

# --- lock (concurrent execution prevention) ---

@test "lock: modifying command fails when lock is held" {
  # Simulate a running instance by creating lock dir with live PID
  mkdir -p "$LOCK_DIR"
  echo $$ > "$LOCK_DIR/pid"

  run "$BIN" set "$IMAGE_DIR/a.png"
  [ "$status" -eq 1 ]
  [[ "$output" == *"already running"* ]]
}

@test "lock: read-only commands work even when locked" {
  mkdir -p "$LOCK_DIR"
  echo $$ > "$LOCK_DIR/pid"

  run "$BIN" current
  [ "$status" -eq 0 ]
  [ "$output" = "/existing/bg.png" ]

  run "$BIN" list "$IMAGE_DIR"
  [ "$status" -eq 0 ]
}

@test "lock: stale lock is cleaned up automatically" {
  # Create lock with a dead PID
  mkdir -p "$LOCK_DIR"
  echo 99999 > "$LOCK_DIR/pid"

  run "$BIN" set "$IMAGE_DIR/a.png"
  [ "$status" -eq 0 ]
}

@test "lock: lock is released after command completes" {
  run "$BIN" set "$IMAGE_DIR/a.png"
  [ "$status" -eq 0 ]
  # Lock dir should not exist after completion
  [ ! -d "$LOCK_DIR" ]
}
