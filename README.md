# Claude Code ずんだもんHooks パッケージ

Claude Codeでずんだもんの音声による読み上げを実現するパッケージです。

## 🚀 クイックスタート

### 1. 超簡単インストール（推奨）

**VOICEVOX不要！** 音声ファイル付きで即座に使用できます：

```bash
cd /path/to/zundamon-hooks-package
./setup.sh --prebuilt
```

### 2. カスタム音声生成（上級者向け）

自分で音声を作り直したい場合：

```bash
# Docker版VOICEVOX使用（推奨）
./setup.sh

# Windows版VOICEVOX使用
./setup.sh --windows
```

## 📢 読み上げ内容

- **bashコマンド**: 「コマンド実行していいのか確認なのだ」
- **ファイル編集**: 「ファイル編集していいのか確認なのだ」
- **ファイル作成**: 「ファイル作成していいのか確認なのだ」
- **複数編集**: 「複数編集していいのか確認なのだ」
- **Notebook編集**: 「ノートブック編集していいのか確認なのだ」
- **通知**: 「クロードコードが呼んでいるのだ」
- **タスク完了**: 「タスクが完了したのだ」

## 🧪 動作テスト

```bash
./test.sh
```

## 📋 必要環境

- WSL2 (Ubuntu 20.04以上)
- Claude Code
- PowerShell（音声再生用）

## 🎛️ オプション

| オプション | 説明 |
|-----------|------|
| `--prebuilt` | **プリビルド音声使用（VOICEVOX不要・推奨）** |
| `--windows` | Windows版VOICEVOX使用 |
| `--test` | インストール後テスト実行 |
| `--uninstall` | 完全削除 |

## 🔧 音声メッセージの変更

1. `generate-voices.sh`を編集
2. `VOICE_MESSAGES`配列内のテキストを変更
3. 音声ファイル再生成: `./generate-voices.sh --force`

## 🚨 トラブルシューティング

### 音声が聞こえない場合

```bash
# 音声ファイル確認
ls -la /mnt/c/temp/voice/*.wav

# 手動音声テスト
powershell.exe -Command "(New-Object Media.SoundPlayer 'C:\temp\voice\bash_confirm.wav').PlaySync()"
```

### VOICEVOXが起動しない場合

```bash
# Docker版（推奨）
docker run -d --name voicevox-engine -p 50021:50021 voicevox/voicevox_engine:latest

# 接続確認
curl -s http://localhost:50021/version
```

## 🗑️ アンインストール

```bash
./setup.sh --uninstall
```

## 🎉 使用開始

インストール完了後、Claude Codeでbashコマンドを実行してみてください：

```bash
echo "ずんだもん導入完了なのだ！"
```

「コマンド実行していいのか確認なのだ」という可愛い声が聞こえれば成功です！

---

**バージョン**: 1.0.0  
**最終更新**: 2025-07-03