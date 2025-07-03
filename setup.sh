#!/bin/bash

# Claude Code ずんだもんHooks セットアップスクリプト
# 再現性の高いワンクリックインストールシステム

set -euo pipefail

# 設定
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VOICE_DIR="/mnt/c/temp/voice"
readonly PREBUILT_VOICES_DIR="${SCRIPT_DIR}/voices"
readonly CLAUDE_CONFIG_DIR="/home/${USER}/.claude"
readonly CLAUDE_SETTINGS="${CLAUDE_CONFIG_DIR}/settings.json"
readonly BACKUP_DIR="${HOME}/.zundamon-hooks-backup"

# カラー出力
readonly RED='\033[31m'
readonly GREEN='\033[32m'
readonly YELLOW='\033[33m'
readonly BLUE='\033[34m'
readonly NC='\033[0m' # No Color

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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# ヘルプ表示
show_help() {
    cat << EOF
Claude Code ずんだもんHooks セットアップ

使用方法:
  $0 [オプション]

オプション:
  --prebuilt       プリビルド音声ファイル使用（VOICEVOX不要・推奨）
  --test           動作確認のみ実行
  --uninstall      完全アンインストール
  --force          既存設定を強制上書き
  --windows        Windows版VOICEVOX使用（デフォルトはDocker版）
  --dry-run        実際の変更は行わず、実行内容のみ表示
  -h, --help       このヘルプを表示

例:
  $0 --prebuilt     # 最簡単インストール（VOICEVOX不要）
  $0                # 標準インストール（Docker版VOICEVOX）
  $0 --windows      # Windows版VOICEVOX用セットアップ
  $0 --test         # インストール後の動作確認
  $0 --uninstall    # 完全削除

EOF
}

# 環境チェック
check_environment() {
    log_step "環境チェック実行中..."
    
    # WSL2確認
    if ! grep -q "microsoft" /proc/version 2>/dev/null; then
        log_error "WSL2環境ではありません"
        return 1
    fi
    log_info "WSL2環境を確認"
    
    # 必要コマンド確認
    local required_commands=(curl jq)
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "必要なコマンドが見つかりません: $cmd"
            log_info "インストール方法: sudo apt update && sudo apt install $cmd"
            return 1
        fi
    done
    log_info "必要なコマンドを確認"
    
    # PowerShell確認
    if ! command -v powershell.exe >/dev/null 2>&1; then
        log_error "PowerShell.exeにアクセスできません"
        return 1
    fi
    log_info "PowerShell.exeアクセスを確認"
    
    # Claude Code設定ディレクトリ確認
    if [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
        log_error "Claude Code設定ディレクトリが見つかりません: $CLAUDE_CONFIG_DIR"
        log_info "Claude Codeが正しくインストールされているか確認してください"
        return 1
    fi
    log_info "Claude Code設定ディレクトリを確認"
    
    return 0
}

# VOICEVOX接続確認
check_voicevox() {
    log_step "VOICEVOX接続確認中..."
    
    local voicevox_urls=()
    
    if [ "${USE_DOCKER:-true}" = "true" ]; then
        voicevox_urls+=("http://localhost:50021")
    else
        voicevox_urls+=("http://172.29.112.1:50022" "http://172.29.112.1:50021")
    fi
    
    for url in "${voicevox_urls[@]}"; do
        log_info "VOICEVOX接続テスト: $url"
        
        if curl -s --connect-timeout 5 "${url}/version" >/dev/null 2>&1; then
            local version=$(curl -s "${url}/version")
            log_info "VOICEVOX接続成功: $url (バージョン: $version)"
            export VOICEVOX_URL="$url"
            return 0
        fi
    done
    
    log_error "VOICEVOXに接続できません"
    log_info "以下を確認してください:"
    if [ "${USE_DOCKER:-true}" = "true" ]; then
        log_info "1. Docker版VOICEVOXが起動しているか: docker ps | grep voicevox"
        log_info "2. ポート50021がリスニング中か: netstat -tlnp | grep 50021"
        log_info "3. Docker版推奨理由: IP変更問題を回避"
    else
        log_info "1. Windows版VOICEVOXが起動しているか"
        log_info "2. APIサーバーが有効になっているか"
        log_info "3. Windows Firewallでポートが許可されているか"
        log_info "4. 注意: WSL2 IP変更によりアクセス不可になる場合があります"
    fi
    
    return 1
}

# バックアップ作成
create_backup() {
    log_step "設定ファイルバックアップ作成中..."
    
    mkdir -p "$BACKUP_DIR"
    
    if [ -f "$CLAUDE_SETTINGS" ]; then
        local backup_file="${BACKUP_DIR}/settings-$(date +%Y%m%d_%H%M%S).json"
        cp "$CLAUDE_SETTINGS" "$backup_file"
        log_info "バックアップ作成: $backup_file"
        export BACKUP_FILE="$backup_file"
    else
        log_warn "Claude Code設定ファイルが見つかりません: $CLAUDE_SETTINGS"
    fi
}

# 音声ディレクトリ作成
create_voice_directory() {
    log_step "音声ディレクトリ作成中..."
    
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] mkdir -p $VOICE_DIR"
        return 0
    fi
    
    mkdir -p "$VOICE_DIR"
    
    if [ ! -w "$VOICE_DIR" ]; then
        log_error "音声ディレクトリに書き込み権限がありません: $VOICE_DIR"
        return 1
    fi
    
    log_info "音声ディレクトリ作成完了: $VOICE_DIR"
}

# プリビルド音声ファイル使用
use_prebuilt_voices() {
    log_step "プリビルド音声ファイル使用中..."
    
    if [ ! -d "$PREBUILT_VOICES_DIR" ]; then
        log_error "プリビルド音声ディレクトリが見つかりません: $PREBUILT_VOICES_DIR"
        return 1
    fi
    
    local voice_count=$(find "$PREBUILT_VOICES_DIR" -name "*.wav" | wc -l)
    if [ "$voice_count" -eq 0 ]; then
        log_error "プリビルド音声ファイルが見つかりません"
        return 1
    fi
    
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] プリビルド音声ファイルコピーをスキップ"
        return 0
    fi
    
    log_info "プリビルド音声ファイルをコピー中..."
    
    if ! cp "$PREBUILT_VOICES_DIR"/*.wav "$VOICE_DIR"/; then
        log_error "音声ファイルのコピーに失敗しました"
        return 1
    fi
    
    log_info "プリビルド音声ファイル使用完了 ($voice_count ファイル)"
}

# 音声ファイル生成
generate_voice_files() {
    log_step "音声ファイル生成中..."
    
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] 音声ファイル生成をスキップ"
        return 0
    fi
    
    # 音声生成スクリプト実行
    local generate_script="${SCRIPT_DIR}/generate-voices.sh"
    
    if [ ! -f "$generate_script" ]; then
        log_error "音声生成スクリプトが見つかりません: $generate_script"
        return 1
    fi
    
    local generate_opts=""
    if [ "${USE_DOCKER:-true}" = "false" ]; then
        generate_opts="--windows"
    fi
    
    if [ "${FORCE_GENERATE:-false}" = "true" ]; then
        generate_opts="$generate_opts --force"
    fi
    
    log_info "音声生成実行: $generate_script $generate_opts"
    
    if ! "$generate_script" $generate_opts; then
        log_error "音声ファイル生成に失敗しました"
        return 1
    fi
    
    log_info "音声ファイル生成完了"
}

# hooks設定更新
update_hooks_settings() {
    log_step "Claude Code hooks設定更新中..."
    
    local template_file="${SCRIPT_DIR}/hooks-template.json"
    
    if [ ! -f "$template_file" ]; then
        log_error "hooks設定テンプレートが見つかりません: $template_file"
        return 1
    fi
    
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] hooks設定更新をスキップ"
        return 0
    fi
    
    # 既存設定の読み込み
    local current_settings="{}"
    if [ -f "$CLAUDE_SETTINGS" ]; then
        current_settings=$(cat "$CLAUDE_SETTINGS")
    fi
    
    # hooks設定のマージ
    local template_hooks=$(jq '.hooks' "$template_file")
    
    local updated_settings=$(echo "$current_settings" | jq --argjson hooks "$template_hooks" '.hooks = $hooks')
    
    # 設定ファイル更新
    echo "$updated_settings" > "$CLAUDE_SETTINGS"
    
    log_info "hooks設定更新完了"
}

# 動作確認
test_installation() {
    log_step "インストール動作確認中..."
    
    # 音声ファイル確認
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
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        log_error "以下の音声ファイルが見つかりません:"
        printf '%s\n' "${missing_files[@]}"
        return 1
    fi
    
    log_info "全ての音声ファイルを確認"
    
    # hooks設定確認
    if [ -f "$CLAUDE_SETTINGS" ]; then
        if ! jq empty "$CLAUDE_SETTINGS" 2>/dev/null; then
            log_error "Claude Code設定ファイルの形式が無効です"
            return 1
        fi
        
        if ! jq -e '.hooks.onToolCall.bash' "$CLAUDE_SETTINGS" >/dev/null 2>&1; then
            log_error "hooks設定が正しく更新されていません"
            return 1
        fi
        
        log_info "hooks設定を確認"
    else
        log_error "Claude Code設定ファイルが見つかりません"
        return 1
    fi
    
    # 音声再生テスト
    if [ "${TEST_PLAYBACK:-false}" = "true" ]; then
        log_info "音声再生テスト実行中..."
        local test_file="${VOICE_DIR}/bash_confirm.wav"
        
        if powershell.exe -Command "(New-Object Media.SoundPlayer '$(echo $test_file | sed s#/mnt/c#C:#)').PlaySync()" 2>/dev/null; then
            log_info "音声再生テスト成功"
        else
            log_warn "音声再生テストに失敗（音声ファイルは正常に生成されています）"
        fi
    fi
    
    log_info "インストール動作確認完了"
}

# アンインストール
uninstall() {
    log_step "ずんだもんHooksアンインストール中..."
    
    # バックアップからの復元
    if [ -d "$BACKUP_DIR" ]; then
        local latest_backup=$(ls -t "${BACKUP_DIR}"/settings-*.json 2>/dev/null | head -1)
        
        if [ -n "$latest_backup" ] && [ -f "$latest_backup" ]; then
            log_info "設定ファイル復元中: $latest_backup"
            
            if [ "$DRY_RUN" != "true" ]; then
                cp "$latest_backup" "$CLAUDE_SETTINGS"
            fi
            
            log_info "設定ファイル復元完了"
        else
            log_warn "復元可能なバックアップが見つかりません"
        fi
    fi
    
    # 音声ファイル削除
    if [ -d "$VOICE_DIR" ]; then
        log_info "音声ファイル削除中: $VOICE_DIR"
        
        if [ "$DRY_RUN" != "true" ]; then
            rm -rf "$VOICE_DIR"
        fi
        
        log_info "音声ファイル削除完了"
    fi
    
    # バックアップディレクトリ削除（任意）
    if [ "${REMOVE_BACKUPS:-false}" = "true" ] && [ -d "$BACKUP_DIR" ]; then
        log_info "バックアップファイル削除中: $BACKUP_DIR"
        
        if [ "$DRY_RUN" != "true" ]; then
            rm -rf "$BACKUP_DIR"
        fi
        
        log_info "バックアップファイル削除完了"
    fi
    
    log_info "アンインストール完了"
}

# エラーハンドリング
cleanup_on_error() {
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        log_error "セットアップ中にエラーが発生しました (終了コード: $exit_code)"
        
        if [ -n "${BACKUP_FILE:-}" ] && [ -f "$BACKUP_FILE" ]; then
            log_info "設定ファイルを復元中..."
            cp "$BACKUP_FILE" "$CLAUDE_SETTINGS" 2>/dev/null || true
            log_info "設定ファイル復元完了"
        fi
        
        log_info "問題を修正してから再実行してください"
    fi
}

# メイン処理
main() {
    log_info "Claude Code ずんだもんHooks セットアップ開始"
    
    # デフォルト値
    local command="install"
    export DRY_RUN="false"
    export USE_DOCKER="true"
    export USE_PREBUILT="false"
    export FORCE_GENERATE="false"
    export TEST_PLAYBACK="false"
    export REMOVE_BACKUPS="false"
    
    # 引数解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            --prebuilt)
                export USE_PREBUILT="true"
                shift
                ;;
            --test)
                command="test"
                export TEST_PLAYBACK="true"
                shift
                ;;
            --uninstall)
                command="uninstall"
                shift
                ;;
            --force)
                export FORCE_GENERATE="true"
                shift
                ;;
            --windows)
                export USE_DOCKER="false"
                shift
                ;;
            --dry-run)
                export DRY_RUN="true"
                shift
                ;;
            --remove-backups)
                export REMOVE_BACKUPS="true"
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
    
    # エラーハンドリング設定
    trap cleanup_on_error EXIT
    
    # 実行前確認
    if [ "$DRY_RUN" = "true" ]; then
        log_info "ドライランモード: 実際の変更は行いません"
    fi
    
    # コマンド実行
    case $command in
        install)
            check_environment
            
            if [ "${USE_PREBUILT}" = "true" ]; then
                log_info "プリビルド音声ファイルモードでインストール中..."
                create_backup
                create_voice_directory
                use_prebuilt_voices
                update_hooks_settings
                test_installation
                
                log_info "=== プリビルドセットアップ完了 ==="
                log_info "VOICEVOX不要でずんだもん音声が利用可能です"
            else
                log_info "VOICEVOX音声生成モードでインストール中..."
                check_voicevox
                create_backup
                create_voice_directory
                generate_voice_files
                update_hooks_settings
                test_installation
                
                log_info "=== セットアップ完了 ==="
                log_info "Claude Codeでbashコマンドを実行すると、ずんだもんの音声が再生されます"
            fi
            
            log_info "テスト実行: $0 --test"
            ;;
            
        test)
            test_installation
            log_info "動作確認完了"
            ;;
            
        uninstall)
            uninstall
            ;;
            
        *)
            log_error "不明なコマンド: $command"
            exit 1
            ;;
    esac
    
    # エラーハンドリング解除
    trap - EXIT
}

# スクリプト実行
main "$@"