#!/usr/bin/env bats

# image_selector.zsh のテスト
# 画像ファイルの検索・選択

setup() {
  TEST_DIR="$(mktemp -d)"

  # テスト用画像ファイル（ダミー）を作成
  touch "$TEST_DIR/photo1.png"
  touch "$TEST_DIR/photo2.jpg"
  touch "$TEST_DIR/photo3.jpeg"
  touch "$TEST_DIR/photo4.PNG"
  touch "$TEST_DIR/photo5.JPG"

  # 非画像ファイル
  touch "$TEST_DIR/readme.txt"
  touch "$TEST_DIR/script.sh"
  touch "$TEST_DIR/data.csv"
  touch "$TEST_DIR/.hidden.png"

  # 空のサブディレクトリ
  mkdir -p "$TEST_DIR/empty_dir"

  LIB_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../lib" && pwd)"
  source "$LIB_DIR/image_selector.zsh"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# --- gbsw_list_images ---

@test "gbsw_list_images: PNG と JPEG ファイルを一覧取得できる" {
  run gbsw_list_images "$TEST_DIR"
  [ "$status" -eq 0 ]
  # 小文字拡張子の3ファイル + 大文字拡張子の2ファイル = 5ファイル
  [ "$(echo "$output" | wc -l)" -eq 5 ]
}

@test "gbsw_list_images: 非画像ファイルを含まない" {
  run gbsw_list_images "$TEST_DIR"
  [[ "$output" != *"readme.txt"* ]]
  [[ "$output" != *"script.sh"* ]]
  [[ "$output" != *"data.csv"* ]]
}

@test "gbsw_list_images: 隠しファイルを含まない" {
  run gbsw_list_images "$TEST_DIR"
  [[ "$output" != *".hidden.png"* ]]
}

@test "gbsw_list_images: 各行がフルパスである" {
  run gbsw_list_images "$TEST_DIR"
  while IFS= read -r line; do
    [[ "$line" == /* ]]
  done <<< "$output"
}

@test "gbsw_list_images: 空ディレクトリではエラー" {
  run gbsw_list_images "$TEST_DIR/empty_dir"
  [ "$status" -eq 1 ]
}

@test "gbsw_list_images: 存在しないディレクトリではエラー" {
  run gbsw_list_images "$TEST_DIR/no_such_dir"
  [ "$status" -eq 1 ]
}

# --- gbsw_random_image ---

@test "gbsw_random_image: 画像パスを1つ返す" {
  run gbsw_random_image "$TEST_DIR"
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | wc -l)" -eq 1 ]
}

@test "gbsw_random_image: 返されたパスは対応画像である" {
  run gbsw_random_image "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *.png || "$output" == *.jpg || "$output" == *.jpeg || "$output" == *.PNG || "$output" == *.JPG || "$output" == *.JPEG ]]
}

@test "gbsw_random_image: 空ディレクトリではエラー" {
  run gbsw_random_image "$TEST_DIR/empty_dir"
  [ "$status" -eq 1 ]
}

@test "gbsw_random_image: 存在しないディレクトリではエラー" {
  run gbsw_random_image "$TEST_DIR/no_such_dir"
  [ "$status" -eq 1 ]
}
