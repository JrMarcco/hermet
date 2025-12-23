#!/bin/bash
echo "=========================================="
echo "MongoDB 管理员用户创建脚本"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 检查容器状态
echo "1. 检查容器状态..."
echo "----------------------------------------"
RUNNING=$(docker compose ps --format json | jq -r '. | select(.State=="running") | .Name' | wc -l)
TOTAL=13

if [ "$RUNNING" -eq "$TOTAL" ]; then
    echo -e "${GREEN}✓${NC} 所有 $TOTAL 个容器正常运行"
else
    echo -e "${RED}✗${NC} 只有 $RUNNING/$TOTAL 个容器在运行"
fi
echo ""

docker exec mongodb-mongos mongosh --port 27017 admin \
  --tls \
  --tlsCertificateKeyFile /etc/ssl/mongodb/admin-client.pem \
  --tlsCAFile /etc/ssl/mongodb/ca.pem \
  --quiet --eval "
db.createUser({
  user: 'jrmarcco',
  pwd: '<passwd>',
  roles: [ { role: 'root', db: 'admin' } ]
})
" 2>&1 | grep -v "Warning"
