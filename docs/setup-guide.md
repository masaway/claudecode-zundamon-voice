# セットアップガイド

## 含まれるスクリプト

- `Notification.sh` - 通知音声
- `Stop.sh` - タスク完了音声
- `play-voice.sh` - 汎用音声再生スクリプト
- `voice-config.json` - 音声ファイル設定

これらのスクリプトは `~/.claude/hooks-scripts/` ディレクトリに自動配置されます。

## セットアップオプション

| オプション | 説明 |
|-----------|------|
| `--test` | インストール後テスト実行 |
| `--uninstall` | 完全削除 |
| `--dry-run` | 実行内容のみ表示（変更は行わない） |
| `--force` | 既存設定を強制上書き |

## VOICEVOX環境セットアップ

カスタム音声生成を行う場合のVOICEVOX環境設定：

```bash
# Docker版（推奨）
docker run -d --name voicevox-engine -p 50021:50021 voicevox/voicevox_engine:latest

# 接続確認
curl -s http://localhost:50021/version
```

## 音声設定の変更

### 設定ファイルによる音声割り当て

生成した音声を使用するには、`hooks-scripts/voice-config.json` を編集します：

```json
{
  "voice_mappings": {
    "Notification": "notification.wav", 
    "Stop": "task_completion.wav"
  },
  "voice_dir": "/mnt/c/temp/voice"
}
```

| hooks用途 | 設定キー | デフォルトファイル | 説明 |
|-----------|-----------|-------------------|------|
| 通知 | `Notification` | `notification.wav` | 通知音声 |
| タスク完了 | `Stop` | `task_completion.wav` | タスク完了音声 |

### 音声変更の完全手順

**ステップ1: 新しい音声を生成**
```bash
./generate-voices.sh
# テキスト入力: お好みのメッセージ
# ファイル名: my_custom_voice
```

**ステップ2: 設定ファイルを更新**
```bash
# hooks-scripts/voice-config.json を編集
{
  "voice_mappings": {
    "Notification": "my_custom_voice.wav", 
    "Stop": "task_completion.wav"
  },
  "voice_dir": "/mnt/c/temp/voice"
}
```

## 複数キャラクターでの音声生成

```bash
# 春日部つむぎで生成
./generate-voices.sh --speaker 3

# 四国めたん（あまあま）で生成  
./generate-voices.sh --speaker 2
```