# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ルール
- 常に日本語で応答すること

## プロジェクト概要

このプロジェクトはClaude CodeとVOICEVOXを統合して、ずんだもんの音声による読み上げ機能を提供するhooksシステムです。Claude Codeの各種ツール実行時に音声フィードバックを提供します。

## 主要コマンド

### セットアップ・インストール
```bash
# プリビルド音声を使用したインストール（推奨）
./setup.sh

# 動作確認
./setup.sh --test

# 完全アンインストール
./setup.sh --uninstall

# ドライランモード（実際の変更なし）
./setup.sh --dry-run
```

### 音声生成
```bash
# 対話式音声生成
./generate-voices.sh

# Windows版VOICEVOX使用
./generate-voices.sh --windows

# バッチモード（hooks用音声生成）
./generate-voices.sh --batch
```

### 権限設定
```bash
# 実行権限付与（git clone後に必要）
chmod +x *.sh
```

## システム構成

### 音声ファイル管理
- **保存場所**: `/mnt/c/temp/voice/`
- **プリビルド音声**: `voices/` ディレクトリ内の事前生成済みファイル
- **音声フォーマット**: WAV形式
- **文字コード**: UTF-8対応

### Hooks統合
- **設定ファイル**: `hooks-template.json`
- **スクリプト配置**: `~/.claude/hooks-scripts/`
- **設定更新**: `~/.claude/settings.json` と `~/.claude.json` の両方を更新
- **マッチャーパターン**: 不使用（NotificationとStopのみ）

### VOICEVOX統合
- **Docker版**: `http://localhost:50021` (推奨)
- **Windows版**: `http://172.29.112.1:50022`
- **キャラクター**: ずんだもん (Speaker ID: 1)

## ファイル構成

```
zundamon-hooks-package/
├── setup.sh                 # メインセットアップスクリプト
├── generate-voices.sh        # 音声生成ツール
├── hooks-template.json       # hooks設定テンプレート
├── voices/                   # プリビルド音声ファイル
│   ├── notification.wav
│   └── task_completion.wav
└── hooks-scripts/           # hooksスクリプト群
    ├── Notification.sh      # 通知
    ├── Stop.sh             # タスク完了
    ├── play-voice.sh       # 汎用音声再生
    └── voice-config.json   # 音声設定
```

## 開発時の注意事項

### 音声設定変更
1. `hooks-scripts/voice-config.json` でファイルマッピングを設定
2. 新しい音声ファイルは `/mnt/c/temp/voice/` に配置
3. PowerShellによる音声再生はWSL2環境で動作

### 音声再生タイミング
- **Notification**: システム通知時に音声再生
- **Stop**: タスク完了時に音声再生
- **PreToolUse**: 削除済み（ツール実行前の音声再生は行わない）

### デバッグ・確認方法
```bash
# 音声ファイル存在確認
ls -la /mnt/c/temp/voice/*.wav

# 手動音声テスト
powershell.exe -Command "(New-Object Media.SoundPlayer 'C:\temp\voice\notification.wav').PlaySync()"

# VOICEVOX接続確認
curl -s http://localhost:50021/version

# hooks設定確認
jq '.hooks' ~/.claude/settings.json
```

### トラブルシューティング
- 音声が再生されない場合は hooks設定を確認
- VOICEVOX接続エラーは Docker コンテナ起動を確認
- 権限エラーは `chmod +x *.sh` で実行権限付与

## 重要な設計原則

- **非同期音声再生**: hooksは非ブロッキングで実行
- **エラーハンドリング**: 音声再生失敗時もClaude Code実行を継続
- **WSL2/Windows統合**: PowerShellによるクロスプラットフォーム音声再生
- **キャッシュ戦略**: 音声ファイルは事前生成してリアルタイム合成を回避