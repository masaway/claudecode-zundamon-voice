#!/bin/bash

# VOICEVOX音声キャッシュ生成スクリプト (パッケージ版)
# Claude Code hooks用の音声ファイルを事前生成

set -euo pipefail

# 設定
VOICE_DIR="/mnt/c/temp/voice"
SPEAKER_ID="1"  # ずんだもん
VOICEVOX_URL="http://localhost:50021"  # Docker版デフォルト

# 音声メッセージ定義
declare -A VOICE_MESSAGES=(
    ["bash_confirm"]="コマンド実行していいのか確認なのだ"
    ["edit_confirm"]="ファイル編集していいのか確認なのだ"
    ["write_confirm"]="ファイル作成していいのか確認なのだ"
    ["multiedit_confirm"]="複数編集していいのか確認なのだ"
    ["notebook_confirm"]="ノートブック編集していいのか確認なのだ"
    ["notification"]="クロードコードが呼んでいるのだ"
    ["task_completion"]="タスクが完了したのだ"
)

# カラー出力関数
print_info() {
    echo -e "\033[32m[INFO]\033[0m $1"
}

print_error() {
    echo -e "\033[31m[ERROR]\033[0m $1"
}

print_warning() {
    echo -e "\033[33m[WARNING]\033[0m $1"
}

# VOICEVOX接続確認
check_voicevox() {
    print_info "VOICEVOX接続確認中: ${VOICEVOX_URL}"
    
    if ! curl -s --connect-timeout 5 "${VOICEVOX_URL}/version" > /dev/null; then
        print_error "VOICEVOXに接続できません: ${VOICEVOX_URL}"
        return 1
    fi
    
    local version=$(curl -s "${VOICEVOX_URL}/version")
    print_info "VOICEVOX接続成功 (バージョン: ${version})"
    return 0
}

# ディレクトリ作成
create_directories() {
    print_info "音声キャッシュディレクトリを作成中..."
    mkdir -p "${VOICE_DIR}"
    
    if [ ! -w "${VOICE_DIR}" ]; then
        print_error "音声ディレクトリに書き込み権限がありません: ${VOICE_DIR}"
        return 1
    fi
    
    print_info "ディレクトリ作成完了: ${VOICE_DIR}"
}

# 音声ファイル生成
generate_voice() {
    local name="$1"
    local text="$2"
    local output_file="${VOICE_DIR}/${name}.wav"
    
    print_info "音声生成中: ${name} - '${text}'"
    
    # 既存ファイルがある場合はスキップ (--force オプションで強制上書き)
    if [ -f "${output_file}" ] && [ "${FORCE_GENERATE:-false}" != "true" ]; then
        print_warning "既存ファイルをスキップ: ${output_file} (--force で強制上書き)"
        return 0
    fi
    
    # 音声クエリ生成と音声合成
    if curl -s -X POST "${VOICEVOX_URL}/audio_query?speaker=${SPEAKER_ID}" \
            --get --data-urlencode text="${text}" | \
       curl -s -X POST -H "Content-Type: application/json" \
            -d @- "${VOICEVOX_URL}/synthesis?speaker=${SPEAKER_ID}" \
            -o "${output_file}"; then
        
        # ファイルサイズ確認
        if [ -f "${output_file}" ] && [ -s "${output_file}" ]; then
            local file_size=$(du -h "${output_file}" | cut -f1)
            print_info "生成完了: ${output_file} (${file_size})"
        else
            print_error "音声ファイル生成失敗: ${output_file}"
            rm -f "${output_file}"
            return 1
        fi
    else
        print_error "音声合成API呼び出しエラー: ${name}"
        return 1
    fi
}

# 統計情報表示
show_statistics() {
    print_info "=== 音声キャッシュ統計 ==="
    
    local total_files=$(find "${VOICE_DIR}" -name "*.wav" 2>/dev/null | wc -l)
    local total_size=$(du -sh "${VOICE_DIR}" 2>/dev/null | cut -f1 || echo "0")
    
    echo "生成ファイル数: ${total_files}"
    echo "総ディスク使用量: ${total_size}"
    echo "保存場所: ${VOICE_DIR}"
    echo ""
    
    if [ "$total_files" -gt 0 ]; then
        print_info "=== ファイル一覧 ==="
        find "${VOICE_DIR}" -name "*.wav" -exec ls -lh {} \; 2>/dev/null | \
            awk '{printf "%-30s %s\n", $9, $5}' | sort
    fi
}

# メイン処理
main() {
    print_info "VOICEVOX音声キャッシュ生成開始"
    
    # 引数解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                FORCE_GENERATE="true"
                print_info "強制上書きモード有効"
                shift
                ;;
            --windows)
                VOICEVOX_URL="http://172.29.112.1:50022"
                print_info "Windows版VOICEVOX使用: ${VOICEVOX_URL}"
                shift
                ;;
            --speaker)
                SPEAKER_ID="$2"
                print_info "スピーカーID設定: ${SPEAKER_ID}"
                shift 2
                ;;
            -h|--help)
                echo "使用方法: $0 [オプション]"
                echo ""
                echo "オプション:"
                echo "  --force       既存ファイルを強制上書き"
                echo "  --windows     Windows版VOICEVOX使用 (デフォルト: Docker版)"
                echo "  --speaker ID  スピーカーID指定 (デフォルト: 1)"
                echo "  -h, --help    このヘルプを表示"
                exit 0
                ;;
            *)
                print_error "不明なオプション: $1"
                print_info "使用方法: $0 --help"
                exit 1
                ;;
        esac
    done
    
    # 実行
    check_voicevox || exit 1
    create_directories || exit 1
    
    # 各音声ファイル生成
    local success_count=0
    local total_count=${#VOICE_MESSAGES[@]}
    
    for name in "${!VOICE_MESSAGES[@]}"; do
        if generate_voice "${name}" "${VOICE_MESSAGES[${name}]}"; then
            ((success_count++))
        fi
    done
    
    # 結果確認
    if [ "${success_count}" -eq "${total_count}" ]; then
        print_info "全ての音声ファイル生成完了 (${success_count}/${total_count})"
        show_statistics
    else
        print_error "一部の音声ファイル生成に失敗 (${success_count}/${total_count})"
        exit 1
    fi
}

# スクリプト実行
main "$@"