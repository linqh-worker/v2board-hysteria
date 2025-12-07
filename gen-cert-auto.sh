#!/bin/bash

#############################################
# ACME 自动申请/续签 + 自动重启 Docker Hysteria
#############################################

DOMAIN="example.com"     # ⚠️ 不要写 *.example.com
OUT_DIR="/root/hysteria"

KEY_FILE="$OUT_DIR/example.com.key"
CRT_FILE="$OUT_DIR/example.com.crt"

RENEW_THRESHOLD=30        # 剩余天数 < 30 自动续签
CF_API="你的Cloudflare_API_Token"   # ⚠️ 必填

DOCKER_CONTAINER="hysteria"   # Docker 容器名称

mkdir -p "$OUT_DIR"

# 修正之前错误：若为目录则删除
[ -d "$KEY_FILE" ] && rm -rf "$KEY_FILE"
[ -d "$CRT_FILE" ] && rm -rf "$CRT_FILE"


#############################################
# 是否需要续签？
#############################################
should_renew() {
    if [ ! -f "$CRT_FILE" ]; then
        return 0
    fi

    end_date=$(openssl x509 -noout -enddate -in "$CRT_FILE" | cut -d= -f2)
    end_ts=$(date -d "$end_date" +%s)
    now_ts=$(date +%s)
    days_left=$(( (end_ts - now_ts) / 86400 ))

    echo "📅 当前证书剩余：$days_left 天"

    [ "$days_left" -lt "$RENEW_THRESHOLD" ] && return 0 || return 1
}


#############################################
# 申请 / 安装 证书
#############################################
issue_cert() {

    echo "🔁 开始申请/续签 Let's Encrypt 泛域名证书..."

    export CF_Token="$CF_API"

    ~/.acme.sh/acme.sh --issue \
        --dns dns_cf \
        -d "$DOMAIN" \
        -d "*.$DOMAIN" \
        --server letsencrypt \
        --keylength ec-256 \
        --force

    ~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
        --ecc \
        --key-file "$KEY_FILE" \
        --fullchain-file "$CRT_FILE" \
        --reloadcmd "docker restart $DOCKER_CONTAINER"

    echo "✅ 证书安装完成"
    echo "🔑 Key:  $KEY_FILE"
    echo "📜 CRT:  $CRT_FILE"
    echo "♻️ 已自动重启 Docker 容器：$DOCKER_CONTAINER"
}


#############################################
# 安装 acme.sh（如未安装）
#############################################
if ! command -v ~/.acme.sh/acme.sh >/dev/null; then
    echo "📦 正在安装 acme.sh ..."
    curl https://get.acme.sh | sh
    source ~/.bashrc
fi


#############################################
# 主流程
#############################################
if should_renew; then
    issue_cert
else
    echo "🔒 当前证书有效，无需续签。"
fi
