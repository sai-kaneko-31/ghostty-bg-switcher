#!/usr/bin/env bash
# config.zsh - Ghostty 設定ファイルの読み書き & リロード

# 設定ファイルのパスを返す
# 優先順: GBSW_CONFIG_PATH > XDG > macOS Application Support
gbsw_config_path() {
  if [[ -n "$GBSW_CONFIG_PATH" ]]; then
    echo "$GBSW_CONFIG_PATH"
    return 0
  fi

  local xdg_path="${HOME}/.config/ghostty/config"
  if [[ -f "$xdg_path" ]]; then
    echo "$xdg_path"
    return 0
  fi

  local mac_path="${HOME}/Library/Application Support/com.mitchellh.ghostty/config"
  if [[ -f "$mac_path" ]]; then
    echo "$mac_path"
    return 0
  fi

  echo "Error: Ghostty config file not found" >&2
  return 1
}

# 指定キーの値を取得
gbsw_config_get() {
  local key="$1"
  local config_path
  config_path="$(gbsw_config_path)" || return 1

  local value
  value=$(grep -E "^${key} *= *" "$config_path" 2>/dev/null | head -1 | sed "s/^${key} *= *//")

  if [[ -z "$value" ]]; then
    return 1
  fi

  # 前後の空白をトリム
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  echo "$value"
  return 0
}

# 指定キーの値を設定（なければ追加、あれば更新）
gbsw_config_set() {
  local key="$1"
  local val="$2"
  local config_path
  config_path="$(gbsw_config_path)" || return 1

  if grep -qE "^${key} *= *" "$config_path" 2>/dev/null; then
    # 既存行を更新
    sed -i'' -e "s|^${key} *= *.*|${key} = ${val}|" "$config_path"
  else
    # 末尾に追加
    echo "${key} = ${val}" >> "$config_path"
  fi
}

# 指定キーの行を削除
gbsw_config_remove() {
  local key="$1"
  local config_path
  config_path="$(gbsw_config_path)" || return 1

  sed -i'' -e "/^${key} *= */d" "$config_path"
  return 0
}

# Ghostty に設定リロードを通知
gbsw_reload_config() {
  if [[ -n "$GBSW_NO_RELOAD" ]]; then
    return 0
  fi
  pkill -SIGUSR2 ghostty 2>/dev/null || true
  return 0
}
