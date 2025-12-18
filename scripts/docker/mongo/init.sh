#!/bin/bash

# 创建数据目录
mkdir config-svr-1-data
mkdir config-svr-2-data
mkdir config-svr-3-data

mkdir shard1-primary-data
mkdir shard1-secondary-1-data
mkdir shard1-secondary-2-data

mkdir shard2-primary-data
mkdir shard2-secondary-1-data
mkdir shard2-secondary-2-data

mkdir shard3-primary-data
mkdir shard3-secondary-1-data
mkdir shard3-secondary-2-data


# 1.生成 keyfile ( 用于集群内部验证 )
# MongoDB 密钥文件的标准硬性要求密钥长度为 756 位，因此使用 openssl rand -base64 756 生成密钥文件。
openssl rand -base64 756 > keyfile
chmod 400 keyfile
