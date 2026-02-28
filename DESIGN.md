# DESIGN.md - ghostty-bg-switcher 設計書

## 目的

Ghostty ターミナルの背景画像を CLI コマンド1つで切り替えられるようにする。
壁紙フォルダを指定して、ランダムや順送りで背景を変更できる。

## 対象OS

macOS のみ

## Ghostty の背景画像設定

Ghostty は設定ファイル内の以下のキーで背景画像を制御する:

| キー | 説明 | デフォルト |
|------|------|------------|
| `background-image` | 画像ファイルパス (PNG/JPEG) | なし |
| `background-image-opacity` | 不透明度 (0.0〜) | `1.0` |
| `background-image-position` | 位置 (center, top-left 等) | `center` |
| `background-image-fit` | フィット方法 (contain/cover/stretch/none) | `contain` |
| `background-image-repeat` | タイル表示 | `false` |

設定ファイルの場所:
- `$HOME/Library/Application Support/com.mitchellh.ghostty/config` (macOS 優先)
- `$HOME/.config/ghostty/config` (XDG フォールバック)

## CLI インターフェース

```
ghostty-bg-switcher <command> [options]
```

### コマンド一覧

| コマンド | 説明 | 例 |
|----------|------|-----|
| `set <image_path>` | 指定した画像を背景に設定 | `ghostty-bg-switcher set ~/wallpapers/cat.png` |
| `random <directory>` | ディレクトリからランダムに1枚選んで設定 | `ghostty-bg-switcher random ~/wallpapers` |
| `list <directory>` | ディレクトリ内の対応画像を一覧表示 | `ghostty-bg-switcher list ~/wallpapers` |
| `clear` | 背景画像を削除（無効化） | `ghostty-bg-switcher clear` |
| `current` | 現在設定されている背景画像を表示 | `ghostty-bg-switcher current` |

### オプション

| オプション | 説明 | 対象コマンド |
|------------|------|-------------|
| `--opacity <value>` | 不透明度を同時に設定 | `set`, `random` |
| `--fit <mode>` | フィットモードを同時に設定 | `set`, `random` |
| `--config <path>` | 設定ファイルパスを明示指定 | 全コマンド |

## アーキテクチャ

### モジュール構成

```
bin/ghostty-bg-switcher    CLI パーサー & ディスパッチ
        │
        ├── lib/config.zsh           設定ファイルの読み書き
        └── lib/image_selector.zsh   画像ファイルの検索・選択
```

### lib/config.zsh

Ghostty 設定ファイルを安全に読み書きする関数群。

```
gbsw_config_path()           → 設定ファイルのパスを返す
gbsw_config_get <key>        → 指定キーの値を取得
gbsw_config_set <key> <val>  → 指定キーの値を設定（なければ追加、あれば更新）
gbsw_config_remove <key>     → 指定キーの行を削除
```

**設定更新の方針:**
- 既存の行がある場合 → その行を書き換え（sed による in-place 編集）
- 行がない場合 → ファイル末尾に追加
- 元のコメントや他の設定は一切変更しない

### lib/image_selector.zsh

ディレクトリ内の画像を操作する関数群。

```
gbsw_list_images <dir>       → 対応画像 (*.png, *.jpg, *.jpeg) のパス一覧を返す
gbsw_random_image <dir>      → ランダムに1枚選んでパスを返す
```

**対応フォーマット:** PNG (.png), JPEG (.jpg, .jpeg)

### bin/ghostty-bg-switcher

CLI のエントリーポイント。引数をパースしてサブコマンドにディスパッチする。

## テスト戦略

bats-core を使った spec-driven development:

1. **test/config.bats** - config.zsh の単体テスト
   - 設定ファイルパスの解決
   - キーの読み取り
   - キーの書き込み（新規追加・既存更新）
   - キーの削除
   - 既存設定を壊さない確認

2. **test/image_selector.bats** - image_selector.zsh の単体テスト
   - 画像ファイルの一覧取得
   - 非画像ファイルの除外
   - 空ディレクトリの処理
   - ランダム選択

3. **test/cli.bats** - CLI の統合テスト
   - 各サブコマンドの正常系
   - 引数不足時のエラー
   - 存在しないファイル/ディレクトリ指定時のエラー
   - ヘルプ表示

## エラーハンドリング

| 状況 | 動作 | 終了コード |
|------|------|------------|
| 引数不足 | usage を stderr に出力 | 2 |
| 存在しないファイル指定 | エラーメッセージ | 1 |
| 存在しないディレクトリ指定 | エラーメッセージ | 1 |
| ディレクトリに画像がない | エラーメッセージ | 1 |
| 設定ファイルが見つからない | エラーメッセージ | 1 |
| 非対応フォーマット | エラーメッセージ | 1 |
