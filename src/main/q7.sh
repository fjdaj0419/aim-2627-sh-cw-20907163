#!/bin/bash
# 指定使用 bash 解释器执行本脚本

set -eu
# 严格模式：-e 任一命令失败立即退出，-u 使用未定义变量即报错

input=${1:?需要输入目录}
# 第 1 个命令行参数是输入目录，未提供时以错误提示退出

output=${2:?需要输出目录}
# 第 2 个命令行参数是输出目录，未提供时以错误提示退出

. "$input/remote.env"
# 加载输入目录下的 remote.env，读取 HOST/PORT/REMOTE_USER/KEY_PATH/KNOWN_HOSTS/REMOTE_LOG 六个连接参数

umask 077
# 把默认权限掩码设为 077，使下面新建的 ssh_config 默认权限即为 600

# 用 heredoc 把 SSH 客户端配置写入输出目录的 ssh_config（定义别名 aim-sentry）
cat > "$output/ssh_config" <<EOF
                                 # 定义连接别名 aim-sentry
Host aim-sentry
                                # 目标主机地址
    HostName $HOST
                                 # 目标端口
    Port $PORT
                                 # 远端登录用户名
    User $REMOTE_USER
                                # 客户端私钥路径（用双引号包裹以容纳空格）
    IdentityFile "$KEY_PATH"
                                # 已核对的目标主机公钥记录文件路径
    UserKnownHostsFile "$KNOWN_HOSTS"
                                # 仅使用配置中指定的私钥，不依赖 agent 或默认密钥
    IdentitiesOnly yes
                                 # 强制校验主机密钥，不关闭主机密钥检查
    StrictHostKeyChecking yes
                                 # 非交互模式，避免等待密码输入
    BatchMode yes
EOF

chmod 600 "$output/ssh_config"
# 把 ssh_config 权限明确设为 600（仅属主可读写）

ssh -F "$output/ssh_config" aim-sentry whoami > "$output/remote-user.txt"
# 用 -F 指定配置、以别名 aim-sentry 连接远端执行 whoami，把返回的用户名写入 remote-user.txt

mkdir -p "$output/received"
# 创建 received 目录，用于存放下载的日志

scp -F "$output/ssh_config" "aim-sentry:$REMOTE_LOG" "$output/received/errors.log"
# 用 -F 指定配置，通过 SCP 把远端日志下载到 received/errors.log

