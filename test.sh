#!/bin/bash

# Claude Code ずんだもんHooks 動作確認テストスクリプト

set -euo pipefail

# 設定
readonly VOICE_DIR="/mnt/c/temp/voice"
readonly CLAUDE_SETTINGS="/home/${USER}/.claude/settings.json"

# カラー出力
readonly RED='\033[31m'
readonly GREEN='\033[32m'
readonly YELLOW='\033[33m'
readonly BLUE='\033[34m'
readonly NC='\033[0m'

# ログ関数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# テスト結果集計
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# テスト関数
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TOTAL_TESTS++))
    log_test "実行中: $test_name"
    
    if eval "$test_command"; then
        ((PASSED_TESTS++))
        log_info "✓ $test_name"
        return 0
    else
        ((FAILED_TESTS++))
        log_error "✗ $test_name"
        return 1
    fi
}

# 音声ファイル存在確認
test_voice_files() {
    local voice_files=(
        "bash_confirm.wav"
        "edit_confirm.wav"
        "write_confirm.wav"
        "multiedit_confirm.wav"
        "notebook_confirm.wav"
        "notification.wav"
        "task_completion.wav"
    )
    
    local missing_files=()
    
    for file in "${voice_files[@]}"; do
        if [ ! -f "${VOICE_DIR}/${file}" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        return 0
    else
        log_error "以下の音声ファイルが見つかりません:"
        printf '  - %s\n' "${missing_files[@]}"
        return 1
    fi
}

# 音声ファイルサイズ確認
test_voice_file_sizes() {
    local min_size=1024  # 1KB
    local small_files=()
    
    for file in "${VOICE_DIR}"/*.wav; do
        if [ -f "$file" ]; then
            local size=$(stat -c%s "$file" 2>/dev/null || echo 0)
            if [ "$size" -lt "$min_size" ]; then
                small_files+=("$(basename "$file")")
            fi
        fi
    done
    
    if [ ${#small_files[@]} -eq 0 ]; then
        return 0
    else
        log_error "以下の音声ファイルのサイズが小さすぎます (${min_size}バイト未満):"
        printf '  - %s\n' "${small_files[@]}"
        return 1
    fi
}

# 音声ファイル形式確認
test_voice_file_formats() {
    local invalid_files=()
    
    for file in "${VOICE_DIR}"/*.wav; do
        if [ -f "$file" ]; then
            if ! file "$file" | grep -q "WAVE" 2>/dev/null; then
                invalid_files+=("$(basename "$file")")
            fi
        fi
    done
    
    if [ ${#invalid_files[@]} -eq 0 ]; then
        return 0
    else
        log_error "以下のファイルは有効なWAV形式ではありません:"
        printf '  - %s\n' "${invalid_files[@]}"
        return 1
    fi
}

# Claude Code設定ファイル確認
test_claude_settings() {
    if [ ! -f "$CLAUDE_SETTINGS" ]; then
        log_error "Claude Code設定ファイルが見つかりません: $CLAUDE_SETTINGS"
        return 1
    fi
    
    # JSON構文確認
    if ! jq empty "$CLAUDE_SETTINGS" 2>/dev/null; then
        log_error "Claude Code設定ファイルのJSON形式が無効です"
        return 1
    fi
    
    return 0
}

# hooks設定確認
test_hooks_configuration() {
    local required_hooks=(
        ".hooks.onToolCall.bash"
        ".hooks.onToolCall.Edit"
        ".hooks.onToolCall.Write"
        ".hooks.onToolCall.MultiEdit"
        ".hooks.onToolCall.NotebookEdit"
        ".hooks.Notification[0]"
        ".hooks.TaskCompletion[0]"
    )
    
    local missing_hooks=()
    
    for hook in "${required_hooks[@]}"; do
        if ! jq -e "$hook" "$CLAUDE_SETTINGS" >/dev/null 2>&1; then
            missing_hooks+=("$hook")
        fi
    done
    
    if [ ${#missing_hooks[@]} -eq 0 ]; then
        return 0
    else
        log_error "以下のhooks設定が見つかりません:"
        printf '  - %s\n' "${missing_hooks[@]}"
        return 1
    fi
}

# PowerShell実行確認
test_powershell_access() {
    if ! command -v powershell.exe >/dev/null 2>&1; then
        log_error "PowerShell.exeにアクセスできません"
        return 1
    fi
    
    # 簡単なコマンド実行テスト
    if ! powershell.exe -Command "Write-Output 'test'" >/dev/null 2>&1; then
        log_error "PowerShell.exeコマンド実行に失敗しました"
        return 1
    fi
    
    return 0
}

# 音声再生テスト
test_voice_playback() {
    local test_file="${VOICE_DIR}/bash_confirm.wav"
    
    if [ ! -f "$test_file" ]; then
        log_error "テスト用音声ファイルが見つかりません: $test_file"
        return 1
    fi
    
    log_info "音声再生テスト実行中..."
    
    # 実際の音声再生テスト（エラーは無視）
    if powershell.exe -Command "(New-Object Media.SoundPlayer '$(echo $test_file | sed s#/mnt/c#C:#)').PlaySync()" 2>/dev/null; then
        log_info "音声再生テスト成功"
        return 0
    else
        log_warn "音声再生テストに失敗（音声設定を確認してください）"
        return 1
    fi
}

# hooks動作シミュレーション
test_hooks_simulation() {
    local test_file="${VOICE_DIR}/bash_confirm.wav"
    
    if [ ! -f "$test_file" ]; then
        log_error "テスト用音声ファイルが見つかりません: $test_file"
        return 1
    fi
    
    # hooks設定から実際のコマンドを抽出して実行
    local hooks_command=$(jq -r '.hooks.onToolCall.bash' "$CLAUDE_SETTINGS" 2>/dev/null)
    
    if [ "$hooks_command" = "null" ] || [ -z "$hooks_command" ]; then
        log_error "bash hooks設定が見つかりません"
        return 1
    fi
    
    log_info "hooks動作シミュレーション実行中..."
    
    # コマンド実行（エラー出力は抑制）
    if eval "$hooks_command" >/dev/null 2>&1; then
        return 0
    else
        log_error "hooks動作シミュレーションに失敗しました"
        return 1
    fi
}

# ディスク使用量確認
test_disk_usage() {
    if [ ! -d "$VOICE_DIR" ]; then
        log_error "音声ディレクトリが見つかりません: $VOICE_DIR"
        return 1
    fi
    
    local total_size=$(du -sh "$VOICE_DIR" 2>/dev/null | cut -f1 || echo "0")
    local file_count=$(find "$VOICE_DIR" -name "*.wav" 2>/dev/null | wc -l)
    
    log_info "音声ファイル統計:"
    log_info "  ファイル数: $file_count"
    log_info "  ディスク使用量: $total_size"
    
    # 使用量が異常に大きい場合の警告
    local size_mb=$(du -sm "$VOICE_DIR" 2>/dev/null | cut -f1 || echo "0")
    if [ "$size_mb" -gt 100 ]; then
        log_warn "音声ファイルのディスク使用量が大きいです: ${size_mb}MB"
    fi
    
    return 0
}

# VOICEVOX接続テスト
test_voicevox_connection() {
    local voicevox_urls=(
        "http://172.29.112.1:50022"  # Windows版
        "http://172.29.112.1:50021"  # Windows版（デフォルト）
        "http://localhost:50021"      # Docker版
    )
    
    for url in "${voicevox_urls[@]}"; do
        if curl -s --connect-timeout 3 "${url}/version" >/dev/null 2>&1; then
            local version=$(curl -s "${url}/version")
            log_info "VOICEVOX接続確認: $url (バージョン: $version)"
            return 0
        fi
    done
    
    log_warn "VOICEVOX APIに接続できません（音声ファイルが既に生成済みの場合は問題ありません）"
    return 1
}

# メイン処理
main() {
    log_info "Claude Code ずんだもんHooks 動作確認テスト開始"
    echo ""
    
    # 基本テスト
    run_test "音声ファイル存在確認" "test_voice_files"
    run_test "音声ファイルサイズ確認" "test_voice_file_sizes"
    run_test "音声ファイル形式確認" "test_voice_file_formats"
    run_test "Claude Code設定ファイル確認" "test_claude_settings"
    run_test "hooks設定確認" "test_hooks_configuration"
    run_test "PowerShell実行確認" "test_powershell_access"
    run_test "ディスク使用量確認" "test_disk_usage"
    
    # オプショナルテスト
    log_info ""
    log_info "=== オプショナルテスト ==="
    
    if [ "${SKIP_AUDIO_TESTS:-false}" != "true" ]; then
        run_test "音声再生テスト" "test_voice_playback"
        run_test "hooks動作シミュレーション" "test_hooks_simulation"
    else
        log_info "音声テストをスキップ (SKIP_AUDIO_TESTS=true)"
    fi
    
    run_test "VOICEVOX接続テスト" "test_voicevox_connection"
    
    # 結果表示
    echo ""
    log_info "=== テスト結果 ==="
    log_info "総テスト数: $TOTAL_TESTS"
    log_info "成功: $PASSED_TESTS"
    log_info "失敗: $FAILED_TESTS"
    
    if [ "$FAILED_TESTS" -eq 0 ]; then
        log_info "全てのテストが成功しました ✓"
        log_info "Claude Codeでbashコマンドを実行すると、ずんだもんの音声が再生されます"
        exit 0
    else
        log_error "一部のテストが失敗しました ✗"
        log_info "setup.shを再実行するか、手動で問題を解決してください"
        exit 1
    fi
}

# ヘルプ表示
show_help() {
    cat << EOF
Claude Code ずんだもんHooks 動作確認テスト

使用方法:
  $0 [オプション]

オプション:
  --skip-audio     音声再生テストをスキップ
  -h, --help       このヘルプを表示

環境変数:
  SKIP_AUDIO_TESTS=true  音声テストをスキップ

例:
  $0                      # 全テスト実行
  $0 --skip-audio         # 音声テストをスキップ
  SKIP_AUDIO_TESTS=true $0  # 環境変数でスキップ

EOF
}

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-audio)
            export SKIP_AUDIO_TESTS="true"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "不明なオプション: $1"
            show_help
            exit 1
            ;;
    esac
done

# メイン処理実行
main