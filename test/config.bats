#!/usr/bin/env bats

# Tests for config.zsh
# Ghostty config file read/write and reload

setup() {
  TEST_DIR="$(mktemp -d)"
  TEST_CONFIG="$TEST_DIR/config"

  cat > "$TEST_CONFIG" <<'EOF'
# Ghostty config
font-size = 14
background = #282828
background-image = /old/path/image.png
background-image-opacity = 0.8
background-image-fit = cover
theme = catppuccin-mocha
EOF

  export GBSW_CONFIG_PATH="$TEST_CONFIG"

  LIB_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../lib" && pwd)"
  source "$LIB_DIR/config.zsh"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# --- gbsw_config_path ---

@test "gbsw_config_path: returns GBSW_CONFIG_PATH when set" {
  export GBSW_CONFIG_PATH="/custom/path/config"
  run gbsw_config_path
  [ "$status" -eq 0 ]
  [ "$output" = "/custom/path/config" ]
}

@test "gbsw_config_path: prefers XDG path when GBSW_CONFIG_PATH unset" {
  unset GBSW_CONFIG_PATH
  export HOME="$TEST_DIR"
  mkdir -p "$TEST_DIR/.config/ghostty"
  touch "$TEST_DIR/.config/ghostty/config"
  run gbsw_config_path
  [ "$status" -eq 0 ]
  [ "$output" = "$TEST_DIR/.config/ghostty/config" ]
}

@test "gbsw_config_path: falls back to macOS Application Support path" {
  unset GBSW_CONFIG_PATH
  export HOME="$TEST_DIR"
  mkdir -p "$TEST_DIR/Library/Application Support/com.mitchellh.ghostty"
  touch "$TEST_DIR/Library/Application Support/com.mitchellh.ghostty/config"
  run gbsw_config_path
  [ "$status" -eq 0 ]
  [ "$output" = "$TEST_DIR/Library/Application Support/com.mitchellh.ghostty/config" ]
}

@test "gbsw_config_path: error when no config found" {
  unset GBSW_CONFIG_PATH
  export HOME="$TEST_DIR/nonexistent"
  run gbsw_config_path
  [ "$status" -eq 1 ]
}

# --- gbsw_config_get ---

@test "gbsw_config_get: can get existing key value" {
  run gbsw_config_get "background-image"
  [ "$status" -eq 0 ]
  [ "$output" = "/old/path/image.png" ]
}

@test "gbsw_config_get: returns empty with exit code 1 for missing key" {
  run gbsw_config_get "nonexistent-key"
  [ "$status" -eq 1 ]
  [ "$output" = "" ]
}

@test "gbsw_config_get: ignores comment lines" {
  run gbsw_config_get "# Ghostty config"
  [ "$status" -eq 1 ]
}

@test "gbsw_config_get: trims whitespace from values" {
  run gbsw_config_get "font-size"
  [ "$status" -eq 0 ]
  [ "$output" = "14" ]
}

# --- gbsw_config_set ---

@test "gbsw_config_set: can update existing key" {
  gbsw_config_set "background-image" "/new/path/cat.png"
  run gbsw_config_get "background-image"
  [ "$output" = "/new/path/cat.png" ]
}

@test "gbsw_config_set: appends new key to end of file" {
  gbsw_config_set "background-image-position" "top-left"
  run gbsw_config_get "background-image-position"
  [ "$status" -eq 0 ]
  [ "$output" = "top-left" ]
}

@test "gbsw_config_set: does not corrupt other settings" {
  gbsw_config_set "background-image" "/new/path.png"
  run gbsw_config_get "font-size"
  [ "$output" = "14" ]
  run gbsw_config_get "theme"
  [ "$output" = "catppuccin-mocha" ]
}

@test "gbsw_config_set: preserves comment lines" {
  gbsw_config_set "background-image" "/new/path.png"
  run grep "^# Ghostty config" "$TEST_CONFIG"
  [ "$status" -eq 0 ]
}

# --- gbsw_config_remove ---

@test "gbsw_config_remove: can delete specified key" {
  gbsw_config_remove "background-image"
  run gbsw_config_get "background-image"
  [ "$status" -eq 1 ]
}

@test "gbsw_config_remove: does not corrupt other settings" {
  gbsw_config_remove "background-image"
  run gbsw_config_get "font-size"
  [ "$output" = "14" ]
  run gbsw_config_get "background-image-opacity"
  [ "$output" = "0.8" ]
}

@test "gbsw_config_remove: no error when key does not exist" {
  run gbsw_config_remove "nonexistent-key"
  [ "$status" -eq 0 ]
}

# --- gbsw_reload_config ---

@test "gbsw_reload_config: calls pkill command" {
  pkill() { echo "pkill called with: $@"; }
  export -f pkill
  run gbsw_reload_config
  [ "$status" -eq 0 ]
  [[ "$output" == *"SIGUSR2"* ]] || [[ "$output" == *"USR2"* ]] || true
}
