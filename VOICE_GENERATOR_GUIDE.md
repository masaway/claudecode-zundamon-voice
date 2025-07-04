# VOICEVOX対話式音声生成ツール利用ガイド

## 📖 概要

`generate-voices.sh`は、VOICEVOXを使用してずんだもんの音声ファイルを対話形式で生成するツールです。
テキストを入力するだけで、簡単に音声ファイルを作成できます。

## 🚀 基本的な使い方

### 1. 対話モードで開始

```bash
./generate-voices.sh
```

実行すると以下のような対話が始まります：

```
=== VOICEVOX対話式音声生成ツール ===
スピーカー: 1 (ずんだもん)
保存先: /mnt/c/temp/voice

空のテキストを入力すると終了します
ファイル名に拡張子(.wav)は不要です

--- 音声生成 #1 ---
生成したいテキスト: こんにちは、ずんだもんなのだ
保存ファイル名 (例: my_voice): greeting
[INFO] 音声生成中: 'こんにちは、ずんだもんなのだ' → /mnt/c/temp/voice/greeting.wav
[SUCCESS] 生成完了: /mnt/c/temp/voice/greeting.wav (15K)
音声をテスト再生しますか？ [y/N]: y
[SUCCESS] テスト再生完了

--- 音声生成 #2 ---
生成したいテキスト: [空白で終了]
[INFO] 終了します

```

### 2. 連続で複数の音声を生成

対話モードでは、空のテキストを入力するまで連続で音声生成できます：

```
--- 音声生成 #1 ---
生成したいテキスト: おはようなのだ
保存ファイル名: morning

--- 音声生成 #2 ---
生成したいテキスト: お疲れ様なのだ
保存ファイル名: thanks

--- 音声生成 #3 ---
生成したいテキスト: [Enter] ← 空白で終了
```

## 🎛️ オプション

### スピーカー変更

```bash
# 春日部つむぎで音声生成
./generate-voices.sh --speaker 3

# 四国めたん（あまあま）で音声生成
./generate-voices.sh --speaker 2
```

### VOICEVOX接続先変更

```bash
# Windows版VOICEVOX使用
./generate-voices.sh --windows

# Docker版（デフォルト）
./generate-voices.sh
```

### バッチモード（hooks用音声生成）

```bash
# hooks用の定型音声ファイルを一括生成
./generate-voices.sh --batch
```

## 🎨 利用できるキャラクター

| Speaker ID | キャラクター名 | 音声タイプ |
|------------|----------------|------------|
| 0 | 四国めたん | ノーマル |
| 1 | ずんだもん | ノーマル ⭐（デフォルト） |
| 2 | 四国めたん | あまあま |
| 3 | 春日部つむぎ | ノーマル |
| 8 | 春日部つむぎ | ささやき |

※ その他多数のキャラクターが利用可能です

## 📁 ファイル保存について

### 保存場所
- 全ての音声ファイルは `/mnt/c/temp/voice/` に保存されます
- Windowsからは `C:\temp\voice\` でアクセス可能

### ファイル名規則
- 拡張子`.wav`は自動で付与されます
- ファイル名を空白にした場合、`voice_YYYYMMDD_HHMMSS.wav`の形式で自動命名

### 上書き確認
既存ファイルがある場合は上書き確認が表示されます：
```
ファイルが既に存在します。上書きしますか？ [y/N]: 
```

## 🎵 音声テスト機能

生成完了後、音声をテスト再生できます：

```
音声をテスト再生しますか？ [y/N]: y
[SUCCESS] テスト再生完了
```

※ WSL2環境でPowerShellを使用して再生します

## 📊 統計表示

音声生成終了時に統計情報が表示されます：

```
=== 音声ファイル統計 ===
総ファイル数: 5
総ディスク使用量: 150K
保存場所: /mnt/c/temp/voice

=== 最近のファイル (最新5件) ===
greeting.wav             15K
morning.wav              12K
thanks.wav               13K
```

## 🔧 トラブルシューティング

### VOICEVOXに接続できない場合

#### Docker版の場合
```bash
# VOICEVOXコンテナ起動
docker run -d --name voicevox-engine -p 50021:50021 voicevox/voicevox_engine:latest

# 接続確認
curl -s http://localhost:50021/version
```

#### Windows版の場合
1. VOICEVOX.exeを起動
2. 設定からAPIサーバーを有効化
3. ファイアウォールでポート50022を許可

### 音声生成に失敗する場合

```bash
# VOICEVOX接続確認
./generate-voices.sh --help

# ログ確認（詳細エラー表示）
./generate-voices.sh 2>&1 | tee voice_generation.log
```

### 権限エラーの場合

```bash
# 音声ディレクトリの権限確認
ls -la /mnt/c/temp/

# ディレクトリ作成（必要に応じて）
mkdir -p /mnt/c/temp/voice
```

## 💡 活用例

### 1. 通知音声の作成
```bash
./generate-voices.sh
# テキスト: "処理が完了したのだ"
# ファイル名: process_complete
```

### 2. アプリケーション用音声メニュー
```bash
./generate-voices.sh --speaker 3  # 春日部つむぎ
# テキスト: "メニューを選択してください"
# ファイル名: menu_select
```

### 3. エラー通知音声
```bash
./generate-voices.sh
# テキスト: "エラーが発生したのだ、確認が必要なのだ"
# ファイル名: error_notification
```

## 📚 コマンドリファレンス

```bash
# ヘルプ表示
./generate-voices.sh --help

# 対話モード（デフォルト）
./generate-voices.sh

# スピーカー指定
./generate-voices.sh --speaker <ID>

# Windows版VOICEVOX使用
./generate-voices.sh --windows

# バッチモード
./generate-voices.sh --batch

# 組み合わせ例
./generate-voices.sh --speaker 3 --windows
```

## 🔄 従来のhooks用音声生成との違い

| 機能 | 従来版 | 新対話版 |
|------|---------|----------|
| **使用方法** | 定型メッセージの一括生成 | テキスト入力で自由生成 |
| **ファイル名** | 固定（notification.wav等） | 自由指定 |
| **対話性** | なし | あり |
| **テスト再生** | なし | あり |
| **統計表示** | 簡易 | 詳細 |
| **上書き確認** | --forceオプション | 対話確認 |

従来のhooks用音声生成は `--batch` オプションで引き続き利用できます。

---

**更新日**: 2025-07-04  
**バージョン**: 2.0.0（対話版）