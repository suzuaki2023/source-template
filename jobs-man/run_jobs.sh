#!/bin/bash

# 引数の解析
LOOP=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --loop) LOOP=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# 処理対象のフォルダ名（必要に応じて変更）
TARGET_DIR="./jobs"
DONEJOB_DIR="./jobs.done"

# ログファイルのパス
LOG_FILE=".jobs.log"

# ミリ秒を含む現在時刻を取得する関数
current_time() {
    echo $(date '+%Y-%m-%d %H:%M:%S.%3N')
}

# 処理対象のフォルダが存在することを確認
if [ ! -d "$TARGET_DIR" ]; then
    echo "$TARGET_DIR directory not found"
    exit 1
fi

process_folders() {
    # 処理対象フォルダ内の .job フォルダをリストアップして、日付・時刻順にソート

    job_folders=$(ls -dt "$TARGET_DIR"/*.job 2> /dev/null)

    # フォルダを新しい順に処理
    for folder in $job_folders; do
        # フォルダ名を取得（末尾のスラッシュを削除）
        folder_name="${folder%/}"

        # フォルダ内に parameter.json が存在するか確認
        if [ -f "$folder_name/parameters.json" ]; then
            # フォルダ名を .running に変更
            running_folder="${folder_name}.running"
            mv "$folder_name" "$running_folder"

            # main.py を nohup でバックグラウンド実行
            echo "$(current_time) - Running main.py for $running_folder" >> $LOG_FILE

            # カレントディレクトリを保存
            current_directory=$(pwd)

            # 実行ディレクトリへ移動
            cd "$running_folder"

            # jobを実行する
            nohup python main.py "parameters.json" >> "./output.log" 2>&1 &

            # プロセスが完了するまで待つ
            wait $!

            # 実行後にカレントディレクトリを戻す
            cd "$current_directory"

            # 実行が完了したら、フォルダ名を .done に変更
            done_folder="${running_folder%.running}.done"
            mv "$running_folder" "$done_folder"

            # 完了したフォルダを jobs.done フォルダへ移動
            echo "$(current_time) - $done_folder -> $DONEJOB_DIR"
            mv $done_folder $DONEJOB_DIR

            # 完了ログを記録
            echo "$(current_time) - Completed main.py for $done_folder" >> $LOG_FILE
        else
            # parameter.json が存在しない場合のログを記録
            echo "$(current_time)  - parameters.json not found in $folder_name" >> $LOG_FILE
        fi
    done
}

# 無限ループ処理
if [ "$LOOP" = true ]; then
    echo "$(current_time) - loop start..."
    while true; do
        process_folders
        sleep 10  # 10秒間隔でフォルダの検索を行う
    done
else
    process_folders
fi