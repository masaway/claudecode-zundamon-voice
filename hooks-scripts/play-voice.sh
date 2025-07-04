#!/bin/bash

# 汎用音声再生スクリプト
# 引数: フック名 (PreToolUse, Notification, Stop)

set -euo pipefail

HOOK_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/voice-config.json"

# 設定ファイル存在確認
if [ ! -f "$CONFIG_FILE" ]; then
    echo "設定ファイルが見つかりません: $CONFIG_FILE"
    exit 1
fi

# jq が利用可能か確認
if ! command -v jq > /dev/null 2>&1; then
    echo "jq コマンドが見つかりません。インストールしてください。"
    exit 1
fi

# 設定読み込み
VOICE_DIR=$(jq -r '.voice_dir' "$CONFIG_FILE")
VOICE_FILE=$(jq -r ".voice_mappings.${HOOK_NAME}" "$CONFIG_FILE")

# 設定値チェック
if [ "$VOICE_FILE" = "null" ]; then
    echo "フック '${HOOK_NAME}' の音声設定が見つかりません"
    exit 1
fi

# 音声ファイルパス構築
FULL_PATH="${VOICE_DIR}/${VOICE_FILE}"

# ファイル存在確認
if [ ! -f "$FULL_PATH" ]; then
    echo "音声ファイルが見つかりません: $FULL_PATH"
    exit 1
fi

# Windows パス変換して音声再生
WINDOWS_PATH=$(echo "$FULL_PATH" | sed 's#/mnt/c#C:#')

if powershell.exe -Command "(New-Object Media.SoundPlayer \"${WINDOWS_PATH}\").PlaySync()" 2>/dev/null; then
    # 再生成功時は何も出力しない（ログ汚染防止）
    :
else
    echo "音声再生エラー: $FULL_PATH"
fi