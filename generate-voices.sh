#!/bin/bash

# VOICEVOX対話式音声生成ツール
# ユーザーが入力したテキストからずんだもん音声を生成

set -euo pipefail

# 設定
VOICE_DIR="/mnt/c/temp/voice"
SPEAKER_ID="1"  # ずんだもん (デフォルト)
VOICEVOX_URL="http://localhost:50021"  # Docker版デフォルト

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

print_success() {
    echo -e "\033[36m[SUCCESS]\033[0m $1"
}

# ヘルプ表示
show_help() {
    cat << EOF
VOICEVOX対話式音声生成ツール

使用方法:
  $0 [オプション]

オプション:
  --windows     Windows版VOICEVOX使用 (デフォルト: Docker版)
  --speaker ID  スピーカーID指定 (デフォルト: 1 = ずんだもん)
  --batch       バッチモード（対話なし）
  -h, --help    このヘルプを表示

対話モード:
  テキストとファイル名を入力して音声ファイルを生成します。
  空のテキストを入力すると終了します。

例:
  $0                      # 対話モードで開始
  $0 --speaker 3         # 春日部つむぎで音声生成
  $0 --windows           # Windows版VOICEVOX使用

スピーカーID一覧:
  0: 四国めたん (ノーマル)
  1: ずんだもん (ノーマル)  ← デフォルト
  2: 四国めたん (あまあま)
  3: 春日部つむぎ (ノーマル)
  8: 春日部つむぎ (ささやき)
  ... その他多数
EOF
}

# VOICEVOX接続確認
check_voicevox() {
    print_info "VOICEVOX接続確認中: ${VOICEVOX_URL}"
    
    if ! curl -s --connect-timeout 5 "${VOICEVOX_URL}/version" > /dev/null; then
        print_error "VOICEVOXに接続できません: ${VOICEVOX_URL}"
        print_error "以下を確認してください:"
        if [[ "$VOICEVOX_URL" == *"localhost"* ]]; then
            print_error "1. Docker版VOICEVOXが起動しているか"
            print_error "   docker run -d --name voicevox-engine -p 50021:50021 voicevox/voicevox_engine:latest"
        else
            print_error "1. Windows版VOICEVOXが起動しているか"
            print_error "2. APIサーバーが有効になっているか"
        fi
        return 1
    fi
    
    local version=$(curl -s "${VOICEVOX_URL}/version")
    print_info "VOICEVOX接続成功 (バージョン: ${version})"
    return 0
}

# ディレクトリ作成
create_directories() {
    print_info "音声保存ディレクトリを確認中..."
    mkdir -p "${VOICE_DIR}"
    
    if [ ! -w "${VOICE_DIR}" ]; then
        print_error "音声ディレクトリに書き込み権限がありません: ${VOICE_DIR}"
        return 1
    fi
    
    print_info "保存先: ${VOICE_DIR}"
}

# スピーカー情報取得
get_speaker_info() {
    local speakers=$(curl -s "${VOICEVOX_URL}/speakers" | jq -r '.[] | "\(.speaker_uuid):\(.name)"')
    echo "$speakers"
}

# 音声ファイル生成
generate_voice() {
    local text="$1"
    local filename="$2"
    local output_file="${VOICE_DIR}/${filename}"
    
    # .wav拡張子がない場合は追加
    if [[ "$output_file" != *.wav ]]; then
        output_file="${output_file}.wav"
    fi
    
    print_info "音声生成中: '${text}' → ${output_file}"
    
    # 既存ファイル確認
    if [ -f "${output_file}" ]; then
        echo -n "ファイルが既に存在します。上書きしますか？ [y/N]: "
        read -r overwrite
        if [[ ! "$overwrite" =~ ^[yY] ]]; then
            print_warning "スキップしました: ${output_file}"
            return 0
        fi
    fi
    
    # 音声クエリ生成
    local audio_query
    if ! audio_query=$(curl -s -X POST "${VOICEVOX_URL}/audio_query?speaker=${SPEAKER_ID}" \
            --get --data-urlencode "text=${text}"); then
        print_error "音声クエリ生成に失敗しました"
        return 1
    fi
    
    # 音声合成
    if echo "$audio_query" | curl -s -X POST -H "Content-Type: application/json" \
            -d @- "${VOICEVOX_URL}/synthesis?speaker=${SPEAKER_ID}" \
            -o "${output_file}"; then
        
        # ファイルサイズ確認
        if [ -f "${output_file}" ] && [ -s "${output_file}" ]; then
            local file_size=$(du -h "${output_file}" | cut -f1)
            print_success "生成完了: ${output_file} (${file_size})"
            
            # 簡易再生テスト
            echo -n "音声をテスト再生しますか？ [y/N]: "
            read -r play_test
            if [[ "$play_test" =~ ^[yY] ]]; then
                local windows_path=$(echo "$output_file" | sed 's#/mnt/c#C:#')
                if powershell.exe -Command "(New-Object Media.SoundPlayer '${windows_path}').PlaySync()" 2>/dev/null; then
                    print_success "テスト再生完了"
                else
                    print_warning "テスト再生に失敗（ファイルは正常に生成されています）"
                fi
            fi
        else
            print_error "音声ファイル生成失敗: ${output_file}"
            rm -f "${output_file}"
            return 1
        fi
    else
        print_error "音声合成API呼び出しエラー"
        return 1
    fi
}

# 対話モード
interactive_mode() {
    print_success "=== VOICEVOX対話式音声生成ツール ==="
    print_info "スピーカー: ${SPEAKER_ID} (ずんだもん)"
    print_info "保存先: ${VOICE_DIR}"
    print_info ""
    print_info "空のテキストを入力すると終了します"
    print_info "ファイル名に拡張子(.wav)は不要です"
    echo ""
    
    local count=0
    
    while true; do
        echo "--- 音声生成 #$((++count)) ---"
        
        # テキスト入力
        echo -n "生成したいテキスト: "
        read -r text
        
        # 空の場合は終了
        if [ -z "$text" ]; then
            print_info "終了します"
            break
        fi
        
        # ファイル名入力
        echo -n "保存ファイル名 (例: my_voice): "
        read -r filename
        
        # ファイル名が空の場合はデフォルト名
        if [ -z "$filename" ]; then
            filename="voice_$(date +%Y%m%d_%H%M%S)"
            print_info "デフォルトファイル名を使用: ${filename}"
        fi
        
        # 音声生成実行
        if generate_voice "$text" "$filename"; then
            echo ""
        else
            print_error "音声生成に失敗しました"
            echo ""
        fi
    done
    
    # 統計表示
    show_statistics
}

# 統計情報表示
show_statistics() {
    print_info "=== 音声ファイル統計 ==="
    
    local total_files=$(find "${VOICE_DIR}" -name "*.wav" 2>/dev/null | wc -l)
    local total_size=$(du -sh "${VOICE_DIR}" 2>/dev/null | cut -f1 || echo "0")
    
    echo "総ファイル数: ${total_files}"
    echo "総ディスク使用量: ${total_size}"
    echo "保存場所: ${VOICE_DIR}"
    echo ""
    
    if [ "$total_files" -gt 0 ]; then
        print_info "=== 最近のファイル (最新5件) ==="
        find "${VOICE_DIR}" -name "*.wav" -printf '%T@ %p\n' 2>/dev/null | \
            sort -nr | head -5 | while read -r timestamp filepath; do
            local filesize=$(du -h "$filepath" | cut -f1)
            local filename=$(basename "$filepath")
            printf "%-25s %s\n" "$filename" "$filesize"
        done
    fi
}

# バッチモード（従来の音声生成）
batch_mode() {
    print_info "バッチモード: hooks用音声ファイル生成"
    
    # hooks用音声メッセージ定義
    declare -A VOICE_MESSAGES=(
        ["notification"]="クロードコードが呼んでいるのだ"
        ["task_completion"]="タスクが完了したのだ"
    )
    
    local success_count=0
    local total_count=${#VOICE_MESSAGES[@]}
    
    for name in "${!VOICE_MESSAGES[@]}"; do
        if generate_voice "${VOICE_MESSAGES[${name}]}" "${name}"; then
            ((success_count++))
        fi
    done
    
    if [ "${success_count}" -eq "${total_count}" ]; then
        print_success "全ての音声ファイル生成完了 (${success_count}/${total_count})"
    else
        print_error "一部の音声ファイル生成に失敗 (${success_count}/${total_count})"
        exit 1
    fi
}

# メイン処理
main() {
    local batch_mode_flag=false
    
    # 引数解析
    while [[ $# -gt 0 ]]; do
        case $1 in
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
            --batch)
                batch_mode_flag=true
                shift
                ;;
            -h|--help)
                show_help
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
    
    if [ "$batch_mode_flag" = true ]; then
        batch_mode
    else
        interactive_mode
    fi
}

# スクリプト実行
main "$@"