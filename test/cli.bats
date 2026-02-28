#!/usr/bin/env bats

# CLI 統合テスト
# bin/ghostty-bg-switcher のサブコマンドテスト

setup() {
  TEST_DIR="$(mktemp -d)"
  TEST_CONFIG="$TEST_DIR/config"
  IMAGE_DIR="$TEST_DIR/images"

  # テスト用設定ファイル
  cat > "$TEST_CONFIG" <<'EOF'
font-size = 14
background-image = /existing/bg.png
background-image-opacity = 0.5
background-image-fit = contain
EOF

  # テスト用画像ディレクトリ
  mkdir -p "$IMAGE_DIR"
  touch "$IMAGE_DIR/a.png"
  touch "$IMAGE_DIR/b.jpg"
  touch "$IMAGE_DIR/c.jpeg"

  export GBSW_CONFIG_PATH="$TEST_CONFIG"
  # テスト中はリロードを無効化
  export GBSW_NO_RELOAD=1

  BIN="$(cd "$(dirname "$BATS_TEST_FILENAME")/../bin" && pwd)/ghostty-bg-switcher"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# --- ヘルプ ---

@test "引数なしで usage を表示して終了コード2" {
  run "$BIN"
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage"* ]] || [[ "$output" == *"Usage"* ]]
}

@test "--help でヘルプを表示" {
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

@test "set: 画像を設定できる" {
  run "$BIN" set "$IMAGE_DIR/a.png"
  [ "$status" -eq 0 ]
  run grep "^background-image" "$TEST_CONFIG"
  [[ "$output" == *"$IMAGE_DIR/a.png"* ]]
}

@test "set: 存在しないファイルでエラー" {
  run "$BIN" set "/no/such/file.png"
  [ "$status" -eq 1 ]
}

@test "set: 非対応フォーマットでエラー" {
  touch "$TEST_DIR/image.gif"
  run "$BIN" set "$TEST_DIR/image.gif"
  [ "$status" -eq 1 ]
}

@test "set: 引数なしでエラー" {
  run "$BIN" set
  [ "$status" -eq 2 ]
}

@test "set --opacity: 不透明度も同時に設定" {
  run "$BIN" set "$IMAGE_DIR/a.png" --opacity 0.3
  [ "$status" -eq 0 ]
  run grep "^background-image-opacity" "$TEST_CONFIG"
  [[ "$output" == *"0.3"* ]]
}

@test "set --fit: フィットモードも同時に設定" {
  run "$BIN" set "$IMAGE_DIR/a.png" --fit cover
  [ "$status" -eq 0 ]
  run grep "^background-image-fit" "$TEST_CONFIG"
  [[ "$output" == *"cover"* ]]
}

# --- random ---

@test "random: ディレクトリからランダムに画像を設定" {
  run "$BIN" random "$IMAGE_DIR"
  [ "$status" -eq 0 ]
  run grep "^background-image" "$TEST_CONFIG"
  [[ "$output" == *"$IMAGE_DIR/"* ]]
}

@test "random: 存在しないディレクトリでエラー" {
  run "$BIN" random "/no/such/dir"
  [ "$status" -eq 1 ]
}

@test "random: 引数なしでエラー" {
  run "$BIN" random
  [ "$status" -eq 2 ]
}

# --- list ---

@test "list: 画像ファイルの一覧を表示" {
  run "$BIN" list "$IMAGE_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"a.png"* ]]
  [[ "$output" == *"b.jpg"* ]]
  [[ "$output" == *"c.jpeg"* ]]
}

@test "list: 存在しないディレクトリでエラー" {
  run "$BIN" list "/no/such/dir"
  [ "$status" -eq 1 ]
}

# --- clear ---

@test "clear: 背景画像設定を削除" {
  run "$BIN" clear
  [ "$status" -eq 0 ]
  run grep "^background-image " "$TEST_CONFIG"
  [ "$status" -eq 1 ]  # background-image の行が消えている
}

@test "clear: background-image-opacity 等も削除される" {
  run "$BIN" clear
  [ "$status" -eq 0 ]
  run grep "^background-image-opacity" "$TEST_CONFIG"
  [ "$status" -eq 1 ]
  run grep "^background-image-fit" "$TEST_CONFIG"
  [ "$status" -eq 1 ]
}

@test "clear: 他の設定は残る" {
  run "$BIN" clear
  run grep "^font-size" "$TEST_CONFIG"
  [ "$status" -eq 0 ]
}

# --- current ---

@test "current: 現在の背景画像パスを表示" {
  run "$BIN" current
  [ "$status" -eq 0 ]
  [ "$output" = "/existing/bg.png" ]
}

@test "current: 背景画像未設定の場合はメッセージ表示" {
  # background-image を削除
  grep -v '^background-image ' "$TEST_CONFIG" > "${TEST_CONFIG}.tmp" && mv "${TEST_CONFIG}.tmp" "$TEST_CONFIG"
  run "$BIN" current
  [ "$status" -eq 0 ]
  [[ "$output" != "" ]]
}

# --- generate ---

@test "generate: プロンプトなしでエラー" {
  run "$BIN" generate
  [ "$status" -eq 2 ]
}

# --- 不明なサブコマンド ---

@test "不明なサブコマンドでエラー" {
  run "$BIN" unknown_command
  [ "$status" -eq 2 ]
}

# --- --config オプション ---

@test "--config: 指定したパスの設定ファイルを使う" {
  OTHER_CONFIG="$TEST_DIR/other_config"
  echo "background-image = /other/image.png" > "$OTHER_CONFIG"
  unset GBSW_CONFIG_PATH
  run "$BIN" current --config "$OTHER_CONFIG"
  [ "$status" -eq 0 ]
  [ "$output" = "/other/image.png" ]
}
