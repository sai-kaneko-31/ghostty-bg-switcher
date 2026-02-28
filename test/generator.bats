#!/usr/bin/env bats

# generator.zsh のテスト
# Gemini CLI による画像生成

setup() {
  TEST_DIR="$(mktemp -d)"
  SAVE_DIR="$TEST_DIR/generated"

  LIB_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../lib" && pwd)"
  source "$LIB_DIR/generator.zsh"
}

teardown() {
  rm -rf "$TEST_DIR"
  # PATH の復元
  if [ -n "$ORIGINAL_PATH" ]; then
    export PATH="$ORIGINAL_PATH"
  fi
}

# --- gbsw_generate_image ---

@test "gbsw_generate_image: gemini コマンドが見つからない場合エラー" {
  ORIGINAL_PATH="$PATH"
  export PATH="/usr/bin:/bin"  # gemini が存在しない PATH
  run gbsw_generate_image "a beautiful sunset" "$TEST_DIR/output.png"
  [ "$status" -eq 1 ]
  [[ "$output" == *"gemini"* ]]
}

@test "gbsw_generate_image: 出力ディレクトリが存在しない場合は自動作成" {
  # gemini をモック
  mkdir -p "$TEST_DIR/bin"
  cat > "$TEST_DIR/bin/gemini" <<'MOCK'
#!/bin/bash
# ダミー画像を生成（引数から出力先を取得）
for arg in "$@"; do
  case "$prev" in
    --output|-o) echo "dummy" > "$arg"; output_set=1 ;;
  esac
  prev="$arg"
done
# --save オプション対応
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
  # ディレクトリが作成されていること
  [ -d "$SAVE_DIR" ]
}

@test "gbsw_generate_image: プロンプトが空の場合エラー" {
  run gbsw_generate_image "" "$TEST_DIR/output.png"
  [ "$status" -eq 1 ]
}

@test "gbsw_generate_image: 正常時は画像パスを stdout に出力する" {
  # gemini をモック: --save <dir> のあとにダミー画像を作成
  mkdir -p "$TEST_DIR/bin"
  cat > "$TEST_DIR/bin/gemini" <<'MOCK'
#!/bin/bash
# --save <dir> の引数からディレクトリを取得してダミー画像を作成
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
