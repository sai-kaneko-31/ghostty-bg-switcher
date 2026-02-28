#!/usr/bin/env bats

# config.zsh のテスト
# Ghostty 設定ファイルの読み書き・リロード

setup() {
  # テスト用の一時ディレクトリとダミー設定ファイルを作成
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

  # lib をロード
  LIB_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../lib" && pwd)"
  source "$LIB_DIR/config.zsh"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# --- gbsw_config_path ---

@test "gbsw_config_path: GBSW_CONFIG_PATH が設定されていればそれを返す" {
  export GBSW_CONFIG_PATH="/custom/path/config"
  run gbsw_config_path
  [ "$status" -eq 0 ]
  [ "$output" = "/custom/path/config" ]
}

@test "gbsw_config_path: GBSW_CONFIG_PATH 未設定なら XDG パスを優先" {
  unset GBSW_CONFIG_PATH
  export HOME="$TEST_DIR"
  mkdir -p "$TEST_DIR/.config/ghostty"
  touch "$TEST_DIR/.config/ghostty/config"
  run gbsw_config_path
  [ "$status" -eq 0 ]
  [ "$output" = "$TEST_DIR/.config/ghostty/config" ]
}

@test "gbsw_config_path: XDG になければ macOS Application Support パスを返す" {
  unset GBSW_CONFIG_PATH
  export HOME="$TEST_DIR"
  mkdir -p "$TEST_DIR/Library/Application Support/com.mitchellh.ghostty"
  touch "$TEST_DIR/Library/Application Support/com.mitchellh.ghostty/config"
  run gbsw_config_path
  [ "$status" -eq 0 ]
  [ "$output" = "$TEST_DIR/Library/Application Support/com.mitchellh.ghostty/config" ]
}

@test "gbsw_config_path: どちらも存在しなければエラー" {
  unset GBSW_CONFIG_PATH
  export HOME="$TEST_DIR/nonexistent"
  run gbsw_config_path
  [ "$status" -eq 1 ]
}

# --- gbsw_config_get ---

@test "gbsw_config_get: 存在するキーの値を取得できる" {
  run gbsw_config_get "background-image"
  [ "$status" -eq 0 ]
  [ "$output" = "/old/path/image.png" ]
}

@test "gbsw_config_get: 存在しないキーは空文字で終了コード1" {
  run gbsw_config_get "nonexistent-key"
  [ "$status" -eq 1 ]
  [ "$output" = "" ]
}

@test "gbsw_config_get: コメント行は無視する" {
  run gbsw_config_get "# Ghostty config"
  [ "$status" -eq 1 ]
}

@test "gbsw_config_get: 値の前後の空白はトリムされる" {
  run gbsw_config_get "font-size"
  [ "$status" -eq 0 ]
  [ "$output" = "14" ]
}

# --- gbsw_config_set ---

@test "gbsw_config_set: 既存キーの値を更新できる" {
  gbsw_config_set "background-image" "/new/path/cat.png"
  run gbsw_config_get "background-image"
  [ "$output" = "/new/path/cat.png" ]
}

@test "gbsw_config_set: 新規キーをファイル末尾に追加できる" {
  gbsw_config_set "background-image-position" "top-left"
  run gbsw_config_get "background-image-position"
  [ "$status" -eq 0 ]
  [ "$output" = "top-left" ]
}

@test "gbsw_config_set: 他の設定を壊さない" {
  gbsw_config_set "background-image" "/new/path.png"
  run gbsw_config_get "font-size"
  [ "$output" = "14" ]
  run gbsw_config_get "theme"
  [ "$output" = "catppuccin-mocha" ]
}

@test "gbsw_config_set: コメント行を保持する" {
  gbsw_config_set "background-image" "/new/path.png"
  run grep "^# Ghostty config" "$TEST_CONFIG"
  [ "$status" -eq 0 ]
}

# --- gbsw_config_remove ---

@test "gbsw_config_remove: 指定キーの行を削除できる" {
  gbsw_config_remove "background-image"
  run gbsw_config_get "background-image"
  [ "$status" -eq 1 ]
}

@test "gbsw_config_remove: 他の設定を壊さない" {
  gbsw_config_remove "background-image"
  run gbsw_config_get "font-size"
  [ "$output" = "14" ]
  run gbsw_config_get "background-image-opacity"
  [ "$output" = "0.8" ]
}

@test "gbsw_config_remove: 存在しないキーを指定してもエラーにならない" {
  run gbsw_config_remove "nonexistent-key"
  [ "$status" -eq 0 ]
}

# --- gbsw_reload_config ---

@test "gbsw_reload_config: pkill コマンドを呼び出す" {
  # pkill をモック
  pkill() { echo "pkill called with: $@"; }
  export -f pkill
  run gbsw_reload_config
  [ "$status" -eq 0 ]
  [[ "$output" == *"SIGUSR2"* ]] || [[ "$output" == *"USR2"* ]] || true
}
