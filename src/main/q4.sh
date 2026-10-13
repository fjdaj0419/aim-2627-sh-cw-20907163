#!/bin/bash
# Q4：合并日志，按级别提取，保存首尾片段并统计错误行数。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu                                                # 出错即停（e）；未定义变量报错（u）
input=${1:?需要输入目录}                                # 第一个参数：输入目录（内含 boot.log、run.log）
output=${2:?需要输出目录}                               # 第二个参数：输出目录（结果文件都写到这里）

# 1) 合并：boot 在前、run 在后，两文件内容按顺序完整拼成 all.log
cat "$input/boot.log" "$input/run.log" > "$output/all.log"

# 2) 错误提取：级别字段等于 ERROR 的行（用 ^ 锚定行首，只匹配第一个字段，消息里的 ERROR 不算）
grep "^ERROR " "$output/all.log" > "$output/errors.log" || true

# 3) 告警提取：级别字段等于 WARN 或 ERROR 的行（-E 用扩展正则，| 表示“或”）
grep -E "^(WARN|ERROR) " "$output/all.log" > "$output/attention.log" || true

# 4) 末尾日志：取 all.log 的最后 5 行（不足 5 行时 tail 自动返回全部，无需特殊处理）
tail -n 5 "$output/all.log" > "$output/recent.log"

# 5) 首条错误：取 errors.log 的最前 3 行（不足 3 行时 head 自动返回全部）
head -n 3 "$output/errors.log" > "$output/first-errors.log"

# 6) 错误计数：统计错误行数，只写“整数+换行”；无匹配时 grep -c 输出 0 但返回 1，用 || true 兜底
grep -c "^ERROR " "$output/all.log" > "$output/error-count.txt" || true
