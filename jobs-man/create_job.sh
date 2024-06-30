#!/bin/bash

# 現在の日付と時刻を取得
current_datetime=$(date '+%Y%m%d-%H%M%S')

# デフォルトのフォルダ名
default_folder="${current_datetime}.job"

# 引数が指定されていない場合
if [ $# -eq 0 ]; then
    job_folder="$default_folder"
    # .job フォルダを作成
    mkdir -p "$job_folder"
    echo "Created folder: $job_folder"

    # parameters.json ファイルを作成
    cat <<EOL > "${job_folder}/parameters.json"
{
    "input": "./input",
    "output": "./output",
    "log": "./log",
    "jobname": "$job_folder"
}
EOL
    echo "Created parameters.json in $job_folder"

    # input, output, log フォルダを作成
    mkdir -p "${job_folder}/input" "${job_folder}/output" "${job_folder}/log"
    echo "Created input, output, and log folders in $job_folder"

    # main.py ファイルを作成
    cat <<EOL > "${job_folder}/main.py"
import os
import sys
import json
import logging
import platform

# task.py　を呼び出す
import task

# ログ設定
logging.basicConfig(filename='./log/job.log', level=logging.INFO, format='%(asctime)s - %(message)s')

def log_environment():
    """実行環境をログに記録する"""
    logging.info("Execution environment:")
    logging.info(f"Platform: {platform.platform()}")
    logging.info(f"Python version: {platform.python_version()}")
    logging.info(f"Current working directory: {os.getcwd()}")

def read_parameters(parameter_file):
    """parameter.json を読み取る"""
    with open(parameter_file, 'r') as file:
        parameters = json.load(file)
    logging.info(f"Parameters: {parameters}")
    return parameters

def main():
    if len(sys.argv) != 2:
        logging.error("Usage: python main.py <parameter.json>")
        sys.exit(1)

    parameter_file = sys.argv[1]

    # parameter.json が存在するか確認
    if not os.path.isfile(parameter_file):
        logging.error(f"Parameter file {parameter_file} not found.")
        sys.exit(1)

    # 実行環境をログに記録
    log_environment()

    # parameter.json を読み取る
    parameters = read_parameters(parameter_file)

    # 処理に必要な情報を input フォルダから読み取る
    input_folder = parameters['input']
    if not os.path.isdir(input_folder):
        logging.error(f"Input folder {input_folder} not found.")
        sys.exit(1)

    # output フォルダを作成する
    output_folder = parameters['output']
    os.makedirs(output_folder, exist_ok=True)

    # 処理の開始をログに記録
    logging.info("Processing(1) started.")

    # ダミー処理1（例：input フォルダ内のファイルを output フォルダにコピー）
    try:
        for filename in os.listdir(input_folder):
            input_path = os.path.join(input_folder, filename)
            output_path = os.path.join(output_folder, filename)
            with open(input_path, 'r') as infile, open(output_path, 'w') as outfile:
                data = infile.read()
                outfile.write(data)

        # 処理の終了をログに記録
        logging.info("Processing completed successfully.")
        status = "Success"

    except Exception as e:
        logging.error(f"An error occurred: {e}")
        status = "Failure"

    # 終了ステータスをログに記録
    logging.info(f"Process(1) status: {status}")

    # 処理の開始をログに記録
    logging.info("Processing(2) started.")

    # ダミー処理２（例：task.py の main()を呼び出す）
    try:
        task.main(input=input_folder, output=output_folder, log_dir='.log')

    except Exception as e:
        logging.error(f"An error occurred: {e}")
        status = "Failure"

    # 終了ステータスをログに記録
    logging.info(f"Process(2) status: {status}")


if __name__ == "__main__":
    main()
EOL
    echo "Created main.py in $job_folder"

# task.py ファイルを作成する
    cat <<EOL > "${job_folder}/task.py"
import argparse
import logging
import os
import time

def main(input='', output='', log_dir='./log', verbose=0):
    # ログ設定
    log_file = os.path.join(log_dir, 'task.log')
    logging.basicConfig(filename=log_file, level=logging.INFO, 
                        format='%(asctime)s - %(levelname)s - %(message)s')
    
    # 引数を使用した処理
    logging.info(f"Input file: {input}")
    logging.info(f"Output file: {output}")
    if verbose:
        logging.info("Verbose mode is enabled")
        print("Verbose mode is enabled")

    # 30秒まつ
    wait_time = 30
    logging.info(f"Wait {wait_time}sec")
    for i in range(wait_time):
        logging.info(f"{i+1} / {wait_time} sec")
        if verbose:
            print(f"{i+1} / {wait_time} sec")
        time.sleep(1)

    # 例としてファイルの読み書きを行う処理を追加
#    try:
#        with open(input, 'r') as infile:
#            content = infile.read()
#            logging.info(f"Read content from {input}")
#
#        with open(output, 'w') as outfile:
#            outfile.write(content)
#            logging.info(f"Wrote content to {output}")
#    except Exception as e:
#        logging.error(f"An error occurred: {e}")
#        print(f"An error occurred: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="A script to demonstrate argparse usage with logging.")
    
    # 引数の追加
    parser.add_argument("-i", "--input", required=True, help="Input file")
    parser.add_argument("-o", "--output", required=True, help="Output file")
    parser.add_argument("-l", "--log_dir", required=True, help="Log directory")
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose mode")
    
    # 引数を解析
    args = parser.parse_args()
    
    # ログディレクトリの存在確認と作成
    if not os.path.exists(args.log_dir):
        os.makedirs(args.log_dir)
    
    # main 関数を実行
    main(   input= args.input,
            output= args.output,
            log_dir=args.log_dir,
            verbose=args.verbose,)

EOL
    echo "Created task.py in $job_folder"


# 引数に .job フォルダが指定された場合
elif [[ $1 == *.job ]]; then
    if [ ! -d "jobs" ]; then
        mkdir jobs
        echo "Created jobs directory"
    fi

    if [ ! -d "jobs.done" ]; then
        mkdir jobs.done
        echo "Created jobs.done directory"
    fi

    if [ -d "$1" ]; then
        mv "$1" jobs/
        echo "Moved $1 to jobs directory"
    else
        echo "Error: Folder $1 not found"
        exit 1
    fi

else
    echo "Usage: $0 [folder.job]"
    exit 1
fi