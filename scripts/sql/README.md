# SQL 脚本工具使用指南

## 工具说明

### 1. 分库分表SQL生成工具

- **PostgreSQL版本**: `postgresql/sharding-sql-gen.sh`
- **MySQL版本**: `mysql/sharding-sql-gen.sh`

### 2. SQL批量执行工具

- **通用脚本**: `exec-sql.sh`

## 使用流程

### 步骤1: 生成分库分表SQL

在 `postgresql` 或 `mysql` 目录下执行：

```bash
cd postgresql
./sharding-sql-gen.sh -p hermet --all -d 2 -t 4
```

生成的文件结构：
```
postgresql/sharding/
├── db_0/
│   ├── 00_db_init.sql
│   ├── 01_user_init.sql
│   └── 02_channel_init.sql
└── db_1/
    ├── 00_db_init.sql
    ├── 01_user_init.sql
    └── 02_channel_init.sql
```

### 步骤2: 执行SQL文件

返回上级目录执行：

```bash
cd ..  # 回到 scripts/sql 目录

# 执行 db_0 的所有SQL
./exec-sql.sh \
  -t postgresql \
  -h 127.0.0.1 \
  -P 5432 \
  -u jrmarcco \
  -p "your_password" \
  -d hermet_0 \
  -D ./postgresql/sharding/db_0

# 执行 db_1 的所有SQL
./exec-sql.sh \
  -t postgresql \
  -h 127.0.0.1 \
  -P 5432 \
  -u jrmarcco \
  -p "your_password" \
  -d hermet_1 \
  -D ./postgresql/sharding/db_1
```

## 常见问题

### 问题1: 路径错误

❌ **错误示例**（在 postgresql 目录下）:
```bash
cd postgresql
./exec-sql.sh -D ./postgresql/sharding/db_0  # 路径不存在
```

✅ **正确方式**:
```bash
cd postgresql
../exec-sql.sh -D ./sharding/db_0  # 使用相对路径
```

或者：
```bash
cd scripts/sql  # 回到 sql 目录
./exec-sql.sh -D ./postgresql/sharding/db_0
```

### 问题2: 不提供密码参数

如果不想在命令行暴露密码，可以省略 `-p` 参数：

```bash
./exec-sql.sh \
  -t postgresql \
  -h 127.0.0.1 \
  -P 5432 \
  -u jrmarcco \
  -d hermet_0 \
  -D ./postgresql/sharding/db_0
# 会提示: 请输入数据库密码: ****
```

### 问题3: 预览将要执行的文件

使用 `--dry-run` 参数：

```bash
./exec-sql.sh \
  -t postgresql \
  -h 127.0.0.1 \
  -u jrmarcco \
  -d hermet_0 \
  -D ./postgresql/sharding/db_0 \
  --dry-run
```

## MySQL 使用示例

```bash
# 生成SQL
cd mysql
./sharding-sql-gen.sh -p hermet --all -d 2 -t 4

# 执行SQL
cd ..
./exec-sql.sh \
  -t mysql \
  -h 127.0.0.1 \
  -P 3306 \
  -u root \
  -p "your_password" \
  -d hermet_0 \
  -D ./mysql/sharding/db_0
```

## 快速执行脚本示例

创建一个快捷脚本 `run-all.sh`:

```bash
#!/bin/bash

# 数据库配置
DB_TYPE="postgresql"
DB_HOST="127.0.0.1"
DB_PORT="5432"
DB_USER="jrmarcco"
DB_PASSWORD="your_password"
DB_PREFIX="hermet"
DB_COUNT=2

# 执行所有数据库的SQL
for ((i=0; i<DB_COUNT; i++)); do
    echo "正在执行数据库 ${DB_PREFIX}_${i} ..."
    ./exec-sql.sh \
        -t "$DB_TYPE" \
        -h "$DB_HOST" \
        -P "$DB_PORT" \
        -u "$DB_USER" \
        -p "$DB_PASSWORD" \
        -d "${DB_PREFIX}_${i}" \
        -D "./postgresql/sharding/db_${i}"
    
    if [ $? -ne 0 ]; then
        echo "数据库 ${DB_PREFIX}_${i} 执行失败！"
        exit 1
    fi
done

echo "所有数据库执行完成！"
```

