#!/bin/bash
# Q5：运行启动前检查，保存 stdout/stderr、真实退出码和诊断报告。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# 读取 launch.env，得到 LAUNCH_TOOL / MODEL_PATH / CAMERA_PATH（. 是最基本的 source 写法）
. "$input/launch.env"

# 运行检查程序：stdout 用 >，stderr 用 2>，互不混合
if bash "$LAUNCH_TOOL" "$MODEL_PATH" "$CAMERA_PATH" > "$output/stdout.log" 2> "$output/stderr.log"; then
    code=0
else
    code=$?
fi

echo "$code" > "$output/exit-code.txt"

if [ "$code" -eq 0 ]; then
    result=SUCCESS
    reason=NONE
elif [ "$code" -eq 10 ]; then
    result=FAILED
    reason=MODEL_MISSING
else
    result=FAILED
    reason=CAMERA_DENIED
fi

# 三行报告
echo "result=$result" >  "$output/report.txt"
echo "exit_code=$code" >> "$output/report.txt"
echo "reason=$reason" >> "$output/report.txt"
