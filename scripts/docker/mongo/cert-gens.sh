#!/bin/bash
# generate-certs.sh

mkdir -p ssl && cd ssl

# 生成 CA 私钥和证书
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
  -out ca.pem -subj "/CN=MongoCA/O=MongoDB/C=CN"

# 生成服务器私钥
openssl genrsa -out mongo.key 4096

# 创建 SAN 配置文件
cat > san.cnf << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = mongodb
O = MongoDB
C = CN

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost

DNS.2 = mongodb-config-server-1
DNS.3 = mongodb-config-server-2
DNS.4 = mongodb-config-server-3

DNS.5 = mongodb-shard1-primary
DNS.6 = mongodb-shard1-secondary1
DNS.7 = mongodb-shard1-secondary2

DNS.8 = mongodb-shard2-primary
DNS.9 = mongodb-shard2-secondary1
DNS.10 = mongodb-shard2-secondary2

DNS.11 = mongodb-shard3-primary
DNS.12 = mongodb-shard3-secondary1
DNS.13 = mongodb-shard3-secondary2

DNS.14 = mongodb-mongos

# ===== 如果需要外部访问，添加主机名 或 IP =====
# DNS.15 = mongos.yourdomain.com
IP.1 = 127.0.0.1
IP.2 = ::1
IP.3 = 192.168.3.3
EOF

# 生成 CSR 和签名证书
openssl req -new -key mongo.key -out mongo.csr -config san.cnf
openssl x509 -req -in mongo.csr -CA ca.pem -CAkey ca.key -CAcreateserial \
  -out mongo.crt -days 3650 -sha256 -extensions v3_req -extfile san.cnf

# 合并为 PEM 文件
cat mongo.key mongo.crt > mongo.pem

# 生成 keyfile 用于集群内部认证
openssl rand -base64 756 > keyfile
chmod 400 keyfile

echo "证书生成完成"
