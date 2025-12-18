#!/bin/bash
set -e

echo "=========================================="
echo "MongoDB 分片集群部署脚本"
echo "=========================================="

# ==================== 第一步：生成证书和 keyfile ====================
echo ""
echo ">>> [1/6] 生成 Ed25519 TLS 证书..."

mkdir -p tls

# CA 证书
openssl genpkey -algorithm ED25519 -out tls/ca.key
openssl req -x509 -new -key tls/ca.key -days 3650 \
  -out tls/ca.pem -subj "/CN=MongoDB-CA"

# SAN 配置
cat > tls/san.cnf << 'EOF'
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = MongoDB Server

[v3_req]
keyUsage = digitalSignature, keyEncipherment, keyAgreement
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost

DNS.2 = config-svr-1
DNS.3 = config-svr-2
DNS.4 = config-svr-3

DNS.5 = shard1-primary
DNS.6 = shard1-secondary-1
DNS.7 = shard1-secondary-2

DNS.8 = shard2-primary
DNS.9 = shard2-secondary-1
DNS.10 = shard2-secondary-2

DNS.11 = shard3-primary
DNS.12 = shard3-secondary-1
DNS.13 = shard3-secondary-2

DNS.14 = mongos

# ===== 如果需要外部访问，添加主机名 或 IP =====
# DNS.15 = mongos.yourdomain.com
IP.1 = 127.0.0.1
IP.2 = ::1
IP.3 = 192.168.3.3
EOF

# 服务器证书
openssl genpkey -algorithm ED25519 -out tls/mongo.key
openssl req -new -key tls/mongo.key -out tls/mongo.csr -config tls/san.cnf
openssl x509 -req -in tls/mongo.csr \
  -CA tls/ca.pem -CAkey tls/ca.key -CAcreateserial \
  -out tls/mongo.crt -days 3650 \
  -copy_extensions copyall

cat tls/mongo.key tls/mongo.crt > tls/mongo.pem

# Keyfile
echo ">>> 生成 keyfile..."
openssl rand -base64 756 > keyfile
chmod 400 keyfile tls/ca.key tls/mongo.key tls/mongo.pem

# 清理临时文件
rm -f tls/mongo.csr tls/ca.srl tls/san.cnf

echo "✅ 证书生成完成"

# ==================== 辅助函数 ====================
wait_for_mongo() {
  local container=$1
  local port=$2
  local max_attempts=30
  local attempt=1

  echo -n "等待 $container 就绪"
  while [ $attempt -le $max_attempts ]; do
    if docker exec $container mongosh --port $port --quiet --eval "db.runCommand({ping:1})" &>/dev/null; then
      echo " ✓"
      return 0
    fi
    echo -n "."
    sleep 2
    attempt=$((attempt + 1))
  done
  echo " ✗"
  echo "错误: $container 启动超时"
  exit 1
}

wait_for_primary() {
  local container=$1
  local port=$2
  local max_attempts=30
  local attempt=1

  echo -n "等待 $container 副本集选举完成"
  while [ $attempt -le $max_attempts ]; do
    local is_master=$(docker exec $container mongosh --port $port --quiet --eval "db.runCommand({isMaster:1}).ismaster" 2>/dev/null)
    if [ "$is_master" = "true" ]; then
      echo " ✓"
      return 0
    fi
    echo -n "."
    sleep 2
    attempt=$((attempt + 1))
  done
  echo " ✗"
  echo "错误: $container 副本集选举超时"
  exit 1
}

# ==================== 第二步：启动初始化模式 ====================
echo ""
echo ">>> [2/6] 启动集群（初始化模式，无认证）..."
sudo docker compose -f docker-compose.init.yml up -d

# 等待所有节点就绪
echo ""
echo "等待所有 MongoDB 节点启动..."
wait_for_mongo "config-svr-1" 27019
wait_for_mongo "config-svr-2" 27019
wait_for_mongo "config-svr-3" 27019
wait_for_mongo "shard1-primary" 27018
wait_for_mongo "shard1-secondary-1" 27018
wait_for_mongo "shard1-secondary-2" 27018
wait_for_mongo "shard2-primary" 27018
wait_for_mongo "shard2-secondary-1" 27018
wait_for_mongo "shard2-secondary-2" 27018
wait_for_mongo "shard3-primary" 27018
wait_for_mongo "shard3-secondary-1" 27018
wait_for_mongo "shard3-secondary-2" 27018

# ==================== 第三步：初始化副本集 ====================
echo ""
echo ">>> [3/6] 初始化副本集..."

echo "初始化 Config Server 副本集..."
docker exec config-svr-1 mongosh --port 27019 --quiet --eval '
rs.initiate({
  _id: "configReplSet",
  configsvr: true,
  members: [
    { _id: 0, host: "config-svr-1:27019" },
    { _id: 1, host: "config-svr-2:27019" },
    { _id: 2, host: "config-svr-3:27019" }
  ]
});
'
wait_for_primary "config-svr-1" 27019

echo "初始化 Shard1 副本集..."
docker exec shard1-primary mongosh --port 27018 --quiet --eval '
rs.initiate({
  _id: "shard1ReplSet",
  members: [
    { _id: 0, host: "shard1-primary:27018", priority: 2 },
    { _id: 1, host: "shard1-secondary-1:27018", priority: 1 },
    { _id: 2, host: "shard1-secondary-2:27018", priority: 1 }
  ]
});
'
wait_for_primary "shard1-primary" 27018

echo "初始化 Shard2 副本集..."
docker exec shard2-primary mongosh --port 27018 --quiet --eval '
rs.initiate({
  _id: "shard2ReplSet",
  members: [
    { _id: 0, host: "shard2-primary:27018", priority: 2 },
    { _id: 1, host: "shard2-secondary-1:27018", priority: 1 },
    { _id: 2, host: "shard2-secondary-2:27018", priority: 1 }
  ]
});
'
wait_for_primary "shard2-primary" 27018

echo "初始化 Shard3 副本集..."
docker exec shard3-primary mongosh --port 27018 --quiet --eval '
rs.initiate({
  _id: "shard3ReplSet",
  members: [
    { _id: 0, host: "shard3-primary:27018", priority: 2 },
    { _id: 1, host: "shard3-secondary-1:27018", priority: 1 },
    { _id: 2, host: "shard3-secondary-2:27018", priority: 1 }
  ]
});
'
wait_for_primary "shard3-primary" 27018

echo "✅ 所有副本集初始化完成"

# ==================== 第四步：创建 root 用户 ====================
echo ""
echo ">>> [4/6] 创建 root 用户..."

# Config Server 上创建用户
docker exec config-svr-1 mongosh --port 27019 --quiet --eval '
db.getSiblingDB("admin").createUser({
  user: "jrmarcco",
  pwd: "<passwd>",
  roles: [{ role: "root", db: "admin" }]
});
print("Config Server 用户创建成功");
'

# 各 Shard 上创建用户
for shard in shard1-primary shard2-primary shard3-primary; do
  docker exec $shard mongosh --port 27018 --quiet --eval '
  db.getSiblingDB("admin").createUser({
    user: "jrmarcco",
    pwd: "<passwd>",
    roles: [{ role: "root", db: "admin" }]
  });
  ' 2>/dev/null || true
  echo "$shard 用户创建成功"
done

echo "✅ 用户创建完成"

# ==================== 第五步：切换到生产模式 ====================
echo ""
echo ">>> [5/6] 切换到生产模式（启用 TLS + 认证）..."
sudo docker compose -f docker-compose.init.yml down

sleep 3

sudo docker compose up -d

# 等待 mongos 就绪
echo ""
echo "等待 Mongos 路由服务启动..."
sleep 10

# 检查 mongos 是否可连接
max_attempts=30
attempt=1
echo -n "等待 mongos-1 就绪"
while [ $attempt -le $max_attempts ]; do
  if docker exec mongos-1 mongosh --port 27017 \
    --tls --tlsCAFile /etc/mongo/tls/ca.pem \
    --tlsCertificateKeyFile /etc/mongo/tls/mongo.pem \
    -u jrmarcco -p '<passwd>' --authenticationDatabase admin \
    --quiet --eval "db.runCommand({ping:1})" &>/dev/null; then
    echo " ✓"
    break
  fi
  echo -n "."
  sleep 2
  attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
  echo " ✗"
  echo "警告: mongos 连接超时，请手动检查"
fi

# ==================== 第六步：添加分片 ====================
echo ""
echo ">>> [6/6] 添加分片到集群..."

docker exec mongos-1 mongosh --port 27017 \
  --tls --tlsCAFile /etc/mongo/tls/ca.pem \
  --tlsCertificateKeyFile /etc/mongo/tls/mongo.pem \
  -u jrmarcco -p '<passwd>' --authenticationDatabase admin \
  --quiet --eval '
print("添加 Shard1...");
sh.addShard("shard1ReplSet/shard1-primary:27018,shard1-secondary-1:27018,shard1-secondary-2:27018");

print("添加 Shard2...");
sh.addShard("shard2ReplSet/shard2-primary:27018,shard2-secondary-1:27018,shard2-secondary-2:27018");

print("添加 Shard3...");
sh.addShard("shard3ReplSet/shard3-primary:27018,shard3-secondary-1:27018,shard3-secondary-2:27018");

print("");
print("===== 集群分片状态 =====");
sh.status();
'

echo ""
echo "=========================================="
echo "✅ MongoDB 分片集群部署完成！"
echo "=========================================="
