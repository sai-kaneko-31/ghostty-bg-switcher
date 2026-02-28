# CLAUDE.md

## Project Overview

ghostty-bg-switcher は、Ghostty ターミナルエミュレータの背景画像を CLI から手軽に切り替えるためのコマンドラインツール。

## Tech Stack

- **言語:** zsh (macOS 標準シェル)
- **テスト:** bats-core (Bash Automated Testing System)
- **対象OS:** macOS のみ

## Project Structure

```
ghostty-bg-switcher/
├── bin/
│   └── ghostty-bg-switcher    # メインの実行ファイル（CLI エントリーポイント）
├── lib/
│   ├── config.zsh             # Ghostty 設定ファイルの読み書き
│   └── image_selector.zsh     # 画像の検索・選択ロジック
├── test/
│   ├── config.bats            # config.zsh のテスト
│   ├── image_selector.bats    # image_selector.zsh のテスト
│   ├── cli.bats               # CLI 統合テスト
│   └── fixtures/              # テスト用フィクスチャ
├── CLAUDE.md
├── DESIGN.md
├── LICENSE
└── README.md
```

## Development Workflow

- **Spec-Driven Development (SDD):** テストを先に書き、テストが通るように実装する
- テスト実行: `bats test/`
- 個別テスト: `bats test/config.bats`

## Ghostty Config

- macOS のパス: `$HOME/Library/Application Support/com.mitchellh.ghostty/config`
- XDG もサポート: `$HOME/.config/ghostty/config`
- フォーマット: `key = value`（1行1設定、`#` でコメント）
- リロード: `cmd+shift+,` で手動リロード（自動リロードなし）

## Conventions

- 関数名は `gbsw_` プレフィックスを使う（名前空間の衝突回避）
- エラーは stderr に出力
- 終了コード: 0=成功, 1=一般エラー, 2=引数エラー
