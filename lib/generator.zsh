#!/usr/bin/env bash
# generator.zsh - Gemini CLI による画像生成

# Gemini CLI で画像を生成して保存
# 引数: <prompt> <output_path>
# stdout に保存先パスを出力
gbsw_generate_image() {
  local prompt="$1"
  local output_path="$2"

  if [[ -z "$prompt" ]]; then
    echo "Error: Prompt is required" >&2
    return 1
  fi

  if ! command -v gemini &>/dev/null; then
    echo "Error: gemini command not found. Install Gemini CLI first." >&2
    return 1
  fi

  # 出力ディレクトリがなければ作成
  local output_dir
  output_dir="$(dirname "$output_path")"
  mkdir -p "$output_dir"

  # 生成前のファイル一覧を記録
  local before_files
  before_files=$(find "$output_dir" -maxdepth 1 -type f 2>/dev/null | sort)

  # Gemini CLI で画像生成
  local full_prompt="${prompt}. Generate an image suitable for a terminal background."
  if ! gemini --save "$output_dir" "$full_prompt" 2>/dev/null; then
    echo "Error: Image generation failed" >&2
    return 1
  fi

  # 生成後に新しく追加されたファイルを探す
  local after_files
  after_files=$(find "$output_dir" -maxdepth 1 -type f 2>/dev/null | sort)
  local generated_file
  generated_file=$(comm -13 <(echo "$before_files") <(echo "$after_files") | head -1)

  if [[ -n "$generated_file" && "$generated_file" != "$output_path" ]]; then
    mv "$generated_file" "$output_path"
  fi

  if [[ ! -f "$output_path" ]]; then
    echo "Error: Generated image not found at $output_path" >&2
    return 1
  fi

  echo "$output_path"
  return 0
}
