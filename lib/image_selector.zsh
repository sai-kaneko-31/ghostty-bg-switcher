#!/usr/bin/env bash
# image_selector.zsh - 画像ファイルの検索・選択

# 対応画像 (*.png, *.jpg, *.jpeg, 大文字含む) のフルパス一覧を返す
# 隠しファイルは除外
gbsw_list_images() {
  local dir="$1"

  if [[ ! -d "$dir" ]]; then
    echo "Error: Directory not found: $dir" >&2
    return 1
  fi

  # 絶対パスに変換
  dir="$(cd "$dir" && pwd)"

  local images=()
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    local bname
    bname="$(basename "$file")"
    # 隠しファイルを除外
    [[ "$bname" == .* ]] && continue
    images+=("$file")
  done < <(find "$dir" -maxdepth 1 -type f \( \
    -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \
  \) | sort)

  if [[ ${#images[@]} -eq 0 ]]; then
    echo "Error: No supported images found in: $dir" >&2
    return 1
  fi

  printf '%s\n' "${images[@]}"
  return 0
}

# ランダムに1枚選んでフルパスを返す
gbsw_random_image() {
  local dir="$1"
  local image_list
  image_list="$(gbsw_list_images "$dir")" || return 1

  local count
  count=$(echo "$image_list" | wc -l)
  local index=$((RANDOM % count))

  echo "$image_list" | sed -n "$((index + 1))p"
  return 0
}
