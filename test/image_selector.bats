#!/usr/bin/env bats

# Tests for image_selector.zsh
# Image file search and selection

setup() {
  TEST_DIR="$(mktemp -d)"

  touch "$TEST_DIR/photo1.png"
  touch "$TEST_DIR/photo2.jpg"
  touch "$TEST_DIR/photo3.jpeg"
  touch "$TEST_DIR/photo4.PNG"
  touch "$TEST_DIR/photo5.JPG"

  touch "$TEST_DIR/readme.txt"
  touch "$TEST_DIR/script.sh"
  touch "$TEST_DIR/data.csv"
  touch "$TEST_DIR/.hidden.png"

  mkdir -p "$TEST_DIR/empty_dir"

  LIB_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../lib" && pwd)"
  source "$LIB_DIR/image_selector.zsh"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# --- gbsw_list_images ---

@test "gbsw_list_images: lists PNG and JPEG files" {
  run gbsw_list_images "$TEST_DIR"
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | wc -l)" -eq 5 ]
}

@test "gbsw_list_images: excludes non-image files" {
  run gbsw_list_images "$TEST_DIR"
  [[ "$output" != *"readme.txt"* ]]
  [[ "$output" != *"script.sh"* ]]
  [[ "$output" != *"data.csv"* ]]
}

@test "gbsw_list_images: excludes hidden files" {
  run gbsw_list_images "$TEST_DIR"
  [[ "$output" != *".hidden.png"* ]]
}

@test "gbsw_list_images: each line is a full path" {
  run gbsw_list_images "$TEST_DIR"
  while IFS= read -r line; do
    [[ "$line" == /* ]]
  done <<< "$output"
}

@test "gbsw_list_images: error on empty directory" {
  run gbsw_list_images "$TEST_DIR/empty_dir"
  [ "$status" -eq 1 ]
}

@test "gbsw_list_images: error on nonexistent directory" {
  run gbsw_list_images "$TEST_DIR/no_such_dir"
  [ "$status" -eq 1 ]
}

# --- gbsw_random_image ---

@test "gbsw_random_image: returns one image path" {
  run gbsw_random_image "$TEST_DIR"
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | wc -l)" -eq 1 ]
}

@test "gbsw_random_image: returned path is a supported image" {
  run gbsw_random_image "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *.png || "$output" == *.jpg || "$output" == *.jpeg || "$output" == *.PNG || "$output" == *.JPG || "$output" == *.JPEG ]]
}

@test "gbsw_random_image: error on empty directory" {
  run gbsw_random_image "$TEST_DIR/empty_dir"
  [ "$status" -eq 1 ]
}

@test "gbsw_random_image: error on nonexistent directory" {
  run gbsw_random_image "$TEST_DIR/no_such_dir"
  [ "$status" -eq 1 ]
}
