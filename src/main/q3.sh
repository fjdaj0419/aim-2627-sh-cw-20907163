#!/bin/bash
# Q3：复制素材、备份配置、移动草稿、删除 tmp、设定权限并直接运行 hello.sh。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

cd "$output" && mkdir -p sentry_ws && cd "$_"

mkdir -p scripts config backup archive

cp "$input/hello.sh" scripts/hello.sh
cp "$input/robot.conf" config/robot.conf
cp "$input/robot.conf" backup/robot.conf


cp "$input/draft.conf" config/draft.conf
mv config/draft.conf archive/draft.conf.old

rm -rf tmp

chmod 750 scripts/hello.sh
chmod 640 config/robot.conf

scripts/hello.sh > "$output/hello-output.txt"
