# Claude Code ずんだもんHooks パッケージ

Claude Codeでずんだもんの音声による読み上げを実現するパッケージです。

## 🚀 クイックスタート

### 📋 必要環境

- WSL2 (Ubuntu 20.04以上)
- Claude Code
- PowerShell（音声再生用）

### 簡単インストール

**VOICEVOX不要！** 音声ファイル付きで即座に使用できます：

```bash
cd /path/to/zundamon-hooks-package

# git clone後は最初に実行権限を付与
chmod +x *.sh

# インストール実行
./setup.sh
```

### 含まれるスクリプト
- `PreToolUse.sh` - 全ツール実行前の確認音声
- `Notification.sh` - 通知音声
- `Stop.sh` - タスク完了音声
- `play-voice.sh` - 汎用音声再生スクリプト
- `voice-config.json` - 音声ファイル設定

これらのスクリプトは `~/.claude/hooks-scripts/` ディレクトリに自動配置されます。

### 📢 読み上げ内容

- **全ツール実行前**: 「実行許可を求めている」 (PreToolUse.sh)
- **通知**: 「クロードコードが呼んでいるのだ」 (Notification.sh)
- **タスク完了**: 「タスクが完了したのだ」 (Stop.sh)
- **音声再生**: `play-voice.sh` を使用して任意の音声ファイルを再生可能

### 🎛️ オプション

| オプション | 説明 |
|-----------|------|
| `--test` | インストール後テスト実行 |
| `--uninstall` | 完全削除 |
| `--dry-run` | 実行内容のみ表示（変更は行わない） |
| `--force` | 既存設定を強制上書き |


## 🎤 カスタム音声の作成と適用
詳しい使用方法は [`VOICE_GENERATOR_GUIDE.md`](./VOICE_GENERATOR_GUIDE.md) をご覧ください。

### 📋 VOICEVOX環境セットアップ

カスタム音声生成を行う場合のVOICEVOX環境設定：

```bash
# Docker版（推奨）
docker run -d --name voicevox-engine -p 50021:50021 voicevox/voicevox_engine:latest

# 接続確認
curl -s http://localhost:50021/version
```



### 1. 対話式音声生成ツールで音声作成

**注意**: カスタム音声生成にはVOICEVOXが必要です。

```bash
# 対話モードで音声生成（Docker版VOICEVOX使用）
./generate-voices.sh

# Windows版VOICEVOX使用(動作未確認)
./generate-voices.sh --windows

# 例：カスタム通知音声を作成
# 生成したいテキスト: 新しいタスクが開始されるのだ
# 保存ファイル名: custom_notification
```

### 2. 設定ファイルによる音声割り当て
生成した音声を使用するには、`hooks-scripts/voice-config.json` を編集します：

```json
{
  "voice_mappings": {
    "PreToolUse": "custom_notification.wav",
    "Notification": "notification.wav", 
    "Stop": "task_completion.wav"
  },
  "voice_dir": "/mnt/c/temp/voice"
}
```

| hooks用途 | 設定キー | デフォルトファイル | 説明 |
|-----------|-----------|-------------------|------|
| 全ツール実行前 | `PreToolUse` | `notification.wav` | ツール実行前の確認音声 |
| 通知 | `Notification` | `notification.wav` | 通知音声 |
| タスク完了 | `Stop` | `task_completion.wav` | タスク完了音声 |

### 3. 音声変更の完全手順

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
    "PreToolUse": "my_custom_voice.wav",
    "Notification": "notification.wav", 
    "Stop": "task_completion.wav"
  },
  "voice_dir": "/mnt/c/temp/voice"
}
```

### 3. 複数キャラクターでの音声生成

```bash
# 春日部つむぎで生成
./generate-voices.sh --speaker 3

# 四国めたん（あまあま）で生成  
./generate-voices.sh --speaker 2
```


## 🚨 トラブルシューティング

### スクリプトが実行できない場合

**Permission denied**エラーが発生する場合：

```bash
# 実行権限を付与
chmod +x *.sh

# 再度実行
./setup.sh
```

### 音声が聞こえない場合

**基本的には自動設定で動作します**が、うまくいかない場合は以下を確認：

#### 1. hooks設定確認
Claude Codeで以下を実行して現在の設定を確認：

```
/hooks
```

`PreToolUse`、`Notification`、`Stop`の設定が表示されれば正常です。

#### 2. 手動hooks登録（自動設定が反映されない場合）
上記で設定が表示されない場合、手動登録を試してください：

```
/hooks
```

その後、 `hooks-template.json` を参考に設定してください。

#### 3. 音声ファイルとスクリプト確認

```bash
# 音声ファイル確認
ls -la /mnt/c/temp/voice/*.wav

# 手動音声テスト
powershell.exe -Command "(New-Object Media.SoundPlayer 'C:\temp\voice\notification.wav').PlaySync()"

# hooksスクリプト確認
ls -la ~/.claude/hooks-scripts/*.sh
```

### カスタム音声が反映されない場合

新しく生成した音声が再生されない場合：

#### 1. 設定ファイルの確認
音声設定ファイルが正しく設定されているかチェック：

```bash
# 設定ファイルの内容確認
cat ~/.claude/hooks-scripts/voice-config.json

# 設定されている音声ファイルの存在確認
ls -la /mnt/c/temp/voice/notification.wav      # デフォルト
ls -la /mnt/c/temp/voice/task_completion.wav   # デフォルト
# 設定ファイルで指定したカスタムファイルの確認
ls -la /mnt/c/temp/voice/your_custom_file.wav
```

#### 2. 音声ファイルの内容確認
生成した音声が正常か手動テスト：

```bash
# Windows形式のパスで再生テスト
powershell.exe -Command "(New-Object Media.SoundPlayer 'C:\temp\voice\notification.wav').PlaySync()"
```

#### 3. Claude Code再起動
音声ファイルを変更した後、Claude Codeの再起動が必要な場合があります：

```bash
# Claude Codeを一度終了してから再起動
# または新しいセッションを開始
```

#### 4. 音声ファイルの権限確認
音声ファイルが読み取り可能か確認：

```bash
# ファイル権限確認
ls -la /mnt/c/temp/voice/*.wav

# 権限修正（必要に応じて）
chmod 644 /mnt/c/temp/voice/*.wav
```

### カスタム音声生成でVOICEVOXエラーが発生する場合

```bash
# Docker版VOICEVOX起動確認
docker ps | grep voicevox

# 起動していない場合
docker run -d --name voicevox-engine -p 50021:50021 voicevox/voicevox_engine:latest

# 接続確認
curl -s http://localhost:50021/version
```

**注意**: プリビルド音声を使用する場合は、VOICEVOXは不要です。

## 🗑️ アンインストール(動作未確認)

```bash
./setup.sh --uninstall
```


**バージョン**: 1.3.0  
**最終更新**: 2025-07-04