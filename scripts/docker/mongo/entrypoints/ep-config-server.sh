#!/bin/bash
set -e

# 后台启动 MongoDB。
mongod --configsvr --replSet configReplSet --port 27017 --bind_ip_all &

# 获取 MongoDB 进程 ID。
MONGO_PID=$!

# 等待 MongoDB 启动。
sleep 5

check_mongo_status() {
    host=$1
    mongosh --host $host --eval "db.adminCommand('ping')" --quiet
    return $?
}

wait_for_mongo() {
    echo "Waiting for MongoDB instance to be ready ..."

    until check_mongo_status 127.0.0.1; do
        echo "Waiting for MongoDB instance to be ready ..."
        if ! kill -0 $MONGO_PID 2>/dev/null; then
            echo "MongoDB process died unexpectedly."
            exit 1
        fi
        sleep 2
    done
    echo "MongoDB instance is ready."

    for host in mongodb-config-server-2 mongodb-config-server-3; do
        attempt=0
        max_attempts=30

        until check_mongo_status $host || [ $attempt -ge $max_attempts ]; do
            echo "Waiting for $host to be ready ... (attempt $attempt/$max_attempts)"
            attempt=$((attempt+1))
            sleep 2
        done

        if [ $attempt -ge $max_attempts ]; then
            echo "Failed to connect to $host after $max_attempts attempts."
        else
            echo "$host is ready."
        fi
    done

    echo "All MongoDB instances are ready."
}

init_config_server() {
    echo "Initializing config server replica set ..."

    mongosh --eval "db.adminCommand('ping')" || echo "Failed to ping MondoDB"

    mongosh --eval "
        rs.initiate({
            _id: \"configReplSet\",
            configsvr: true,
            members: [
                { _id: 0, host: 'mongodb-config-server-1:27019' },
                { _id: 1, host: 'mongodb-config-server-2:27019' },
                { _id: 2, host: 'mongodb-config-server-3:27019' },
            ]
        })
    " || echo "Failed to initialize config server replica set."
}

echo "Starting MongoDB config server entrypoint script ..."
wait_for_mongo
init_config_server

echo "Initialization completed."
wait $MONGO_PID
