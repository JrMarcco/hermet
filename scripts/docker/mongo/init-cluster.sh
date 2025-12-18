#!/bin/bash

# 初始化 Config Server 副本集
sudo docker exec -it mongodb-config-server-1 mongosh --port 27019 \
  --eval '
rs.initiate({
  _id: "configReplSet",
  configsvr: true,
  members: [
    { _id: 0, host: "mongodb-config-server-1:27019" },
    { _id: 1, host: "mongodb-config-server-2:27019" },
    { _id: 2, host: "mongodb-config-server-3:27019" }
  ]
})'


sudo docker exec -it mongodb-config-server-1 mongosh --port 27019 \
  --tls --tlsCAFile /etc/ssl/ca.pem \
  --tlsCertificateKeyFile /etc/ssl/mongo.pem \
  --eval '
rs.initiate({
  _id: "configReplSet",
  configsvr: true,
  members: [
    { _id: 0, host: "mongodb-config-server-1:27019" },
    { _id: 1, host: "mongodb-config-server-2:27019" },
    { _id: 2, host: "mongodb-config-server-3:27019" }
  ]
})'


# 初始化 Shard1 副本集
sudo docker exec -it mongodb-shard1-primary mongosh --port 27018 \
  --eval '
rs.initiate({
  _id: "shard1ReplSet",
  members: [
    { _id: 0, host: "mongodb-shard1-primary:27018", priority: 2 },
    { _id: 1, host: "mongodb-shard1-secondary1:27018", priority: 1 },
    { _id: 2, host: "mongodb-shard1-secondary2:27018", priority: 1 }
  ]
})'

# 初始化 Shard2 副本集
sudo docker exec -it mongodb-shard2-primary mongosh --port 27018 \
  --eval '
rs.initiate({
  _id: "shard2ReplSet",
  members: [
    { _id: 0, host: "mongodb-shard2-primary:27018", priority: 2 },
    { _id: 1, host: "mongodb-shard2-secondary1:27018", priority: 1 },
    { _id: 2, host: "mongodb-shard2-secondary2:27018", priority: 1 }
  ]
})'

# 初始化 Shard3 副本集
sudo docker exec -it mongodb-shard3-primary mongosh --port 27018 \
  --eval '
rs.initiate({
  _id: "shard3ReplSet",
  members: [
    { _id: 0, host: "mongodb-shard3-primary:27018", priority: 2 },
    { _id: 1, host: "mongodb-shard3-secondary1:27018", priority: 1 },
    { _id: 2, host: "mongodb-shard3-secondary2:27018", priority: 1 }
  ]
})'

# 在 mongos 上创建 root 用户并添加分片
sudo docker exec -it mongodb-mongos mongosh --port 27017 \
  --eval '
db.getSiblingDB("admin").createUser({
  user: "jrmarcco",
  pwd: "<passwd>",
  roles: [{ role: "root", db: "admin" }]
});
'

sudo docker exec -it mongodb-mongos mongosh --port 27017 \
  --eval '
sh.addShard("shard1ReplSet/mongodb-shard1-primary:27018,mongodb-shard1-secondary1:27018,mongodb-shard1-secondary2:27018");
sh.addShard("shard2ReplSet/mongodb-shard2-primary:27018,mongodb-shard2-secondary1:27018,mongodb-shard2-secondary2:27018");
sh.addShard("shard3ReplSet/mongodb-shard3-primary:27018,mongodb-shard3-secondary1:27018,mongodb-shard3-secondary2:27018");
sh.status();
'

sudo docker exec -it mongodb-mongos mongosh --port 27017 \
  --eval '
sh.status();
'
