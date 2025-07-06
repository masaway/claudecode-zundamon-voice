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

### 読み上げ内容

- **通知**: 「クロードコードが呼んでいるのだ」
- **タスク完了**: 「タスクが完了したのだ」

## 🎤 カスタム音声生成

VOICEVOXを使用して、お好みの音声メッセージを作成できます：

```bash
# 対話モードで音声生成
./generate-voices.sh

# Windows版VOICEVOX使用
./generate-voices.sh --windows

# 異なるキャラクターで生成
./generate-voices.sh --speaker 3
```

詳しい使用方法とトラブルシューティングは [`docs/`](./docs/) ディレクトリをご覧ください。

## 📚 ドキュメント

- [詳細セットアップガイド](./docs/setup-guide.md)
- [音声生成ガイド](./docs/voice-generator-guide.md)
- [トラブルシューティング](./docs/troubleshooting.md)

## 🗑️ アンインストール

```bash
./setup.sh --uninstall
```

**バージョン**: 1.3.0  
**最終更新**: 2025-07-04