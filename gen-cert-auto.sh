#!/bin/bash

DOMAIN="example.com"  # ⚠️ 请改成你的主域名（不要带 *）
OUT_DIR="/root/hysteria"
KEY_FILE="$OUT_DIR/$DOMAIN.key"
CRT_FILE="$OUT_DIR/$DOMAIN.crt"
CONFIG_FILE="./wildcard.cnf"
RENEW_THRESHOLD=30  # 剩余天数小于这个就续

mkdir -p "$OUT_DIR"

should_renew() {
    if [ ! -f "$CRT_FILE" ]; then
        return 0  # 没有证书，肯定要生成
    fi

    end_date=$(openssl x509 -enddate -noout -in "$CRT_FILE" | cut -d= -f2)
    end_ts=$(date -d "$end_date" +%s)
    now_ts=$(date +%s)

    days_left=$(( (end_ts - now_ts) / 86400 ))
    echo "📅 证书剩余有效期：$days_left 天"

    if [ "$days_left" -lt "$RENEW_THRESHOLD" ]; then
        return 0
    else
        return 1
    fi
}

if should_renew; then
    echo "🔁 正在生成/续签证书..."

    cat > "$CONFIG_FILE" <<EOF
[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions     = req_ext

[ dn ]
C  = HK
ST = Hong Kong
L  = Hong Kong
O  = Lin Studio
OU = DevOps
CN = *.$DOMAIN

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = *.$DOMAIN
DNS.2 = $DOMAIN
EOF

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$KEY_FILE" \
    -out "$CRT_FILE" \
    -config "$CONFIG_FILE" \
    -extensions req_ext

    rm -f "$CONFIG_FILE"

    echo "✅ 自签证书已生成/更新："
    echo "证书: $CRT_FILE"
    echo "私钥: $KEY_FILE"
else
    echo "✅ 当前证书有效，无需更新。"
fi
