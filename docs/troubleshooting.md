# トラブルシューティング

## スクリプトが実行できない場合

**Permission denied**エラーが発生する場合：

```bash
# 実行権限を付与
chmod +x *.sh

# 再度実行
./setup.sh
```

## 音声が聞こえない場合

**基本的には自動設定で動作します**が、うまくいかない場合は以下を確認：

### 1. hooks設定確認
Claude Codeで以下を実行して現在の設定を確認：

```
/hooks
```

`PreToolUse`、`Notification`、`Stop`の設定が表示されれば正常です。

### 2. 手動hooks登録（自動設定が反映されない場合）
上記で設定が表示されない場合、手動登録を試してください：

```
/hooks
```

その後、 `hooks-template.json` を参考に設定してください。

### 3. 音声ファイルとスクリプト確認

```bash
# 音声ファイル確認
ls -la /mnt/c/temp/voice/*.wav

# 手動音声テスト
powershell.exe -Command "(New-Object Media.SoundPlayer 'C:\temp\voice\notification.wav').PlaySync()"

# hooksスクリプト確認
ls -la ~/.claude/hooks-scripts/*.sh
```

## カスタム音声が反映されない場合

新しく生成した音声が再生されない場合：

### 1. 設定ファイルの確認
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

### 2. 音声ファイルの内容確認
生成した音声が正常か手動テスト：

```bash
# Windows形式のパスで再生テスト
powershell.exe -Command "(New-Object Media.SoundPlayer 'C:\temp\voice\notification.wav').PlaySync()"
```

### 3. Claude Code再起動
音声ファイルを変更した後、Claude Codeの再起動が必要な場合があります：

```bash
# Claude Codeを一度終了してから再起動
# または新しいセッションを開始
```

### 4. 音声ファイルの権限確認
音声ファイルが読み取り可能か確認：

```bash
# ファイル権限確認
ls -la /mnt/c/temp/voice/*.wav

# 権限修正（必要に応じて）
chmod 644 /mnt/c/temp/voice/*.wav
```

## カスタム音声生成でVOICEVOXエラーが発生する場合

```bash
# Docker版VOICEVOX起動確認
docker ps | grep voicevox

# 起動していない場合
docker run -d --name voicevox-engine -p 50021:50021 voicevox/voicevox_engine:latest

# 接続確認
curl -s http://localhost:50021/version
```

**注意**: プリビルド音声を使用する場合は、VOICEVOXは不要です。