jobs-man
===

# 概要

- create_job.sh
- run_job.sh

## create_jobs.sh

### 概要
create_jobs.sh は、指定されたフォルダをリストアップし、日付・時刻順にソートして、新しい順番に .job フォルダ内のparameter.json を引数に main.py を実行するシェルスクリプトです。
実行前後にフォルダ名を変更し、すべての操作を ./job.log に記録します。

### スクリプトの使い方

1. スクリプトをファイルに保存
create_jobs.sh という名前でスクリプトをファイルに保存します。
1. スクリプトに実行権限を付与
保存したスクリプトに実行権限を付与します。
```bash chmod +x create_jobs.sh```
1. スクリプトを実行
スクリプトを実行します。
``` nohup ./create_jobs.sh >> job.log 2>&1 &```

### 詳細説明

create_jobs.sh は以下の手順で動作します：

1. ログファイルの設定
スクリプトは ./job.log ファイルにログを記録します。
```bash LOG_FILE="./job.log" ```
1. フォルダのリストアップとソート
現在のディレクトリ内の .job フォルダを日付・時刻順にリストアップし、新しい順にソートします。
```bash job_folders=$(ls -dt *.job)```
1. リストアップされた各フォルダについて処理を行います。
    1. フォルダ名の取得
フォルダ名の末尾のスラッシュを削除してフォルダ名を取得します。
    ```bash folder_name="${folder%/}"```
    1. parameter.json の存在確認
    フォル ダ内に parameter.json が存在するか確認します。
    ```bash if [ -f "$folder_name/parameter.json" ];```
    1. フォルダ名の変更と main.py の実行
    parameter.json が存在する場合、フォルダ名を .running に変更し、main.py を nohup でバックグラウンド実行します。
        ```bash
        running_folder="${folder_name}.running"
        mv "$folder_name" "$running_folder"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Running main.py for $running_folder" >> $LOG_FILE
        nohup python main.py "$running_folder/parameter.json" >> "$running_folder/output.log" 2>&1 &
        wait $!
        ```
    1. 実行完了後のフォルダ名変更
    main.py の実行が完了したら、フォルダ名を .done に変更します。
        ```bash
        done_folder="${running_folder%.running}.done"
        mv "$running_folder" "$done_folder"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Completed main.py for $done_folder" >> $LOG_FILE
        ```
    1. parameter.json が存在しない場合のログ記録
    parameter.json が存在しない場合、その情報をログに記録します。
        ```bash
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - parameter.json not found in $folder_name" >> $LOG_FILE
        fi
        ```

## run_jobs.sh

### 概要

run_jobs.sh は、指定されたフォルダをリストアップし、日付・時刻順にソートして、新しい順番に .job フォルダ内の parameter.json を引数に main.py を実行するシェルスクリプトです。実行前後にフォルダ名を変更し、すべての操作を ./job.log に記録します。

### スクリプトの使い方

1. スクリプトをファイル（例：run_jobs.sh）に保存します。
1. ターミナルでスクリプトのあるディレクトリに移動します。
1. スクリプトに実行権限を付与します：
    ```bash
    chmod +x run_jobs.sh
    ```
1. スクリプトを実行します：
    ```bash
    nohup ./run_jobs.sh >> job.log 2>&1 &
    ```

### スクリプトの詳細説明

run_jobs.sh は以下の手順で動作します：

1. ログファイルの設定
スクリプトは ./job.log ファイルにログを記録します。
    ```bash
    LOG_FILE="./job.log"
    ```
1. フォルダのリストアップとソート
現在のディレクトリ内の .job フォルダを日付・時刻順にリストアップし、新しい順にソートします。
    ```bash
    job_folders=$(ls -dt *.job)
    ```
1. 各フォルダの処理
リストアップされた各フォルダについて処理を行います。
    - フォルダ名の取得
    フォルダ名の末尾のスラッシュを削除してフォルダ名を取得します。
        ```bash
        folder_name="${folder%/}"
        ```
    - parameter.json の存在確認
    フォルダ内に parameter.json が存在するか確認します。
        ```bash
        if [ -f "$folder_name/parameter.json" ]; then
        ```
    - フォルダ名の変更と main.py の実行
    parameter.json が存在する場合、フォルダ名を .running に変更し、main.py を nohup でバックグラウンド実行します。
        ```bash
        running_folder="${folder_name}.running"
        mv "$folder_name" "$running_folder"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Running main.py for $running_folder" >> $LOG_FILE
        nohup python main.py "$running_folder/parameter.json" >> "$running_folder/output.log" 2>&1 &
        wait $!
        ```
    - 実行完了後のフォルダ名変更
    main.py の実行が完了したら、フォルダ名を .done に変更します。
        ```bash
        done_folder="${running_folder%.running}.done"
        mv "$running_folder" "$done_folder"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Completed main.py for $done_folder" >> $LOG_FILE
        ```
    - parameter.json が存在しない場合のログ記録
    parameter.json が存在しない場合、その情報をログに記録します。
        ```bash
        else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - parameter.json not found in $folder_name" >> $LOG_FILE
        fi
        ```
    - 各操作（実行開始、実行完了、エラーなど）を ./job.log に記録します。

このスクリプトを nohup コマンドと & を使用してバックグラウンドで実行することで、シェルのセッションが終了しても処理を継続することができます。