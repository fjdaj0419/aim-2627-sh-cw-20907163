#!/bin/bash
# Q8：repair 时识别并停止采集器、修复 HTTP 服务；cleanup 时停止修复后的服务。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-repair}

. "$input/process.env"

if [ "$action" = "cleanup" ]; then
    pidfile="$output/service/pid"
    if [ -f "$pidfile" ]; then
        pid=$(cat "$pidfile")
        if [ -n "$pid" ]; then
            kill -TERM "$pid" 2>/dev/null || true
            for _ in $(seq 1 50); do
                if ! kill -0 "$pid" 2>/dev/null; then
                    break
                fi
                sleep 0.1
            done
        fi
    fi
    exit 0
fi

mkdir -p "$output/service"

{
    printf 'pid=%s\n' "$TARGET_PID"
    printf 'user=%s\n' "$(ps -e -o user= -p "$TARGET_PID" | head -1)"
    printf 'state=%s\n' "$(ps -e -o state= -p "$TARGET_PID" | head -1)"
    printf 'command=%s\n' "$(ps -e -o args= -p "$TARGET_PID" | head -1)"
} > "$output/process.txt"

grep -F " $TARGET_TOKEN" "$WORKER_LOG" | grep -E '^(START|TICK) ' > "$output/collector-sample.log"

kill -TERM "$TARGET_PID" 2>/dev/null || true

for _ in $(seq 1 50); do
    if ! kill -0 "$TARGET_PID" 2>/dev/null; then
        break
    fi
    if grep -F "STOP $TARGET_TOKEN" "$WORKER_LOG" >/dev/null 2>&1; then
        break
    fi
    sleep 0.1
done

kill -TERM "$SERVICE_PID" 2>/dev/null || true
for _ in $(seq 1 50); do
    if ! kill -0 "$SERVICE_PID" 2>/dev/null; then
        break
    fi
    sleep 0.1
done

printf 'bind=127.0.0.1\nport=%s\nroute=/status\n' "$TARGET_PORT" > "$output/server.conf"

bash "$START_TOOL" "$output/server.conf" "$output/service"

: > "$output/http-status.txt"
: > "$output/http-body.txt"

for _ in $(seq 1 50); do
    body=$(curl -fsS "http://127.0.0.1:$TARGET_PORT/status" 2>/dev/null || true)
    if [ -n "$body" ]; then
        printf '%s\n' "$body" > "$output/http-body.txt"
        printf '%s\n' "200" > "$output/http-status.txt"
        break
    fi
    sleep 0.1
done

exit 0
