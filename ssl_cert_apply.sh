#!/bin/bash
# ./acme.sh/acme.sh --issue -d *.igedong.cn --dns dns_dp --server https://acme.freessl.cn/v2/DV90/directory/gh3xuva24cik9ks6o8ph

# 检查是否提供了域名参数
if [ $# -ne 1 ]; then
    echo "使用方法: $0 <域名>"
    echo "例如: $0 *.example.com"
    exit 1
fi

# 检查是否已安装acme.sh
if [ ! -f "/root/.acme.sh/acme.sh" ]; then
    echo "检测到acme.sh未安装，正在安装..."
    # 克隆acme.sh仓库
    git clone https://gitee.com/neilpang/acme.sh.git
    if [ $? -ne 0 ]; then
        echo "克隆acme.sh仓库失败！"
        exit 1
    fi
    # 执行安装
    cd acme.sh
    ./acme.sh --install
    if [ $? -ne 0 ]; then
        echo "acme.sh 安装失败！"
        exit 1
    fi
    cd ..
    echo "acme.sh 安装成功！"
fi

DOMAIN=$1
CERT_PATH="cert"
SCRIPT_PATH=$(readlink -f "$0")

# 移除可能的通配符以获取基础域名
BASE_DOMAIN=${DOMAIN#\*.}

# 确保证书目录存在
mkdir -p $CERT_PATH

# 申请证书
/root/.acme.sh/acme.sh --issue -d "$DOMAIN" --dns dns_dp --server https://acme.freessl.cn/v2/DV90/directory/gh3xuva24cik9ks6o8ph

# 检查上一个命令是否成功
if [ $? -ne 0 ]; then
    echo "证书申请失败！"
    exit 1
fi

# 复制证书文件到nginx目录
cp "/root/.acme.sh/$DOMAIN"/fullchain.cer "$CERT_PATH/$DOMAIN.pem"
cp "/root/.acme.sh/$DOMAIN"/"$DOMAIN.key" "$CERT_PATH/$DOMAIN.key"

# 检查文件是否复制成功
if [ -f "$CERT_PATH/$DOMAIN.pem" ] && [ -f "$CERT_PATH/$DOMAIN.key" ]; then
    echo "证书部署成功！"
    echo "证书文件位置："
    echo "- 完整链证书: $CERT_PATH/$DOMAIN.pem"
    echo "- 私钥文件: $CERT_PATH/$DOMAIN.key"
    
    # 添加到crontab，每10天运行一次
    CRON_CMD="0 0 */10 * * $SCRIPT_PATH \"$DOMAIN\""
    (crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" ; echo "$CRON_CMD") | crontab -
    
    echo "已添加自动更新计划任务，每10天检查并自动更新一次证书"
    echo "当前crontab任务："
    crontab -l | grep "$SCRIPT_PATH"
else
    echo "证书文件复制失败！"
    exit 1
fi 