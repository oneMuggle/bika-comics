#!/usr/bin/env bash
# 生成用于 HTTPS-over-SOCKS5 端到端测试的自签名证书。
#
# 用法：bash tool/generate_test_tls_cert.sh
#
# 证书写入 test/fixtures/tls/{cert.pem,key.pem}，并已提交进仓库
# （测试需要它在 CI 上开箱可跑，不依赖 CI 容器里是否装了 openssl）。
#
# 生成命令（等价于脚本内容）：
#   openssl req -x509 -newkey rsa:2048 -nodes \
#     -keyout test/fixtures/tls/key.pem \
#     -out test/fixtures/tls/cert.pem \
#     -days 3650 -subj "/CN=localhost" \
#     -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/test/fixtures/tls"
mkdir -p "$DIR"

openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$DIR/key.pem" \
  -out "$DIR/cert.pem" \
  -days 3650 \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" 2>/dev/null

chmod 644 "$DIR/cert.pem"
chmod 600 "$DIR/key.pem"
echo "generated: $DIR/cert.pem $DIR/key.pem"
