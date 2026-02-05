# 📘 Day 4 学习日志

**主题：Snowflake 接続とクラウドDB連携（DataStage × Snowflake）**

---

## 一、学习目标

本日学习目标是掌握 **DataStage 与 Snowflake 云数据仓库的连接与数据联携方式**，并完成以下任务：

1. 配置并验证 DataStage 到 Snowflake 的数据库连接
2. 将 CSV 文件数据加载至 Snowflake 表
3. 实现 Oracle → Snowflake 的跨数据库数据迁移
4. 从 Snowflake 中执行聚合查询并导出结果
5. 理解 Oracle、Snowflake 与 DataStage 之间的数据类型映射差异

通过本日练习，理解企业云化架构中 **On-Premise → Cloud DWH** 的典型 ETL 场景。

---

## 二、Snowflake 接続設定学习内容

### 1. Snowflake Connector 使用说明

本次练习使用 **Snowflake Connector（ODBC Driver）** 进行连接，主要原因如下：

* Snowflake 为云原生数据仓库，无本地监听端口
* 通过 HTTPS + ODBC 方式连接
* 支持大规模并行写入与查询
* 企业级项目标准连接方式

---

### 2. Snowflake 连接关键参数说明

Snowflake 的连接不同于传统数据库，除账号信息外，还必须指定以下资源：

| 参数        | 说明               |
| --------- | ---------------- |
| Warehouse | 计算资源，决定 SQL 执行能力 |
| Database  | 数据库名称            |
| Schema    | 数据对象所在 Schema    |
| Role      | 决定用户可访问的权限范围     |

---

### 3. 连接字符串格式

```text
Driver=SnowflakeDSIIDriver;
Server={account}.snowflakecomputing.com;
Database={database};
Schema={schema};
Warehouse={warehouse};
Role={role};
```

---

### 4. Snowflake 接続設定书（提交用）

```text
Account: demo_account.snowflakecomputing.com
Warehouse: COMPUTE_WH
Database: TRAINING_DB
Schema: PUBLIC
Role: SYSADMIN
Username: ETL_USER

连接测试结果: 成功
```

---

## 三、作业 2：CSV → Snowflake 数据加载作业

### 1. 作业目标

将 CSV 文件中的交易数据加载到 Snowflake 表 `TRANSACTIONS` 中。

---

### 2. Job 结构设计

```text
Sequential File → Transformer → Snowflake Connector
```

* **Sequential File**：读取 CSV 文件
* **Transformer**：数据类型转换与字段映射
* **Snowflake Connector**：向 Snowflake 表执行 INSERT

---

### 3. Transformer 中的字段映射规则

| CSV 字段           | Snowflake 字段     | 转换处理                           |
| ---------------- | ---------------- | ------------------------------ |
| transaction_id   | TRANSACTION_ID   | 原样输出                           |
| customer_id      | CUSTOMER_ID      | 原样输出                           |
| product_id       | PRODUCT_ID       | 原样输出                           |
| quantity         | QUANTITY         | TO_INTEGER(quantity)           |
| amount           | AMOUNT           | TO_DECIMAL(amount)             |
| transaction_date | TRANSACTION_DATE | TO_TIMESTAMP(transaction_date) |
| payment_method   | PAYMENT_METHOD   | 原样输出                           |

说明：

* Snowflake 的 `TIMESTAMP_NTZ` 不带时区信息
* 时间字段在 DataStage 中需显式转换为 Timestamp
* `LOAD_TIMESTAMP` 使用 Snowflake 默认值，不需映射

---

### 4. 执行结果验证

执行完成后，在 Snowflake 中确认：

```sql
SELECT COUNT(*) FROM TRANSACTIONS;
```

结果为 **8 条记录**，说明 CSV 数据已成功加载。

---

## 四、作业 3：Oracle → Snowflake 数据迁移作业

### 1. 作业目标

将 Day 3 中 Oracle 的 `EMPLOYEES` 表数据迁移至 Snowflake。

---

### 2. Job 结构设计

```text
Oracle Enterprise → Transformer → Snowflake Connector
```

* Oracle Enterprise：执行 SELECT 读取源数据
* Transformer：字段映射与补充元数据
* Snowflake Connector：向目标表 INSERT

---

### 3. 字段映射说明

| Oracle 字段  | Snowflake 字段   | 处理方式              |
| ---------- | -------------- | ----------------- |
| EMP_ID     | EMP_ID         | 原样输出              |
| EMP_NAME   | EMP_NAME       | 原样输出              |
| DEPARTMENT | DEPARTMENT     | 原样输出              |
| HIRE_DATE  | HIRE_DATE      | Date 类型映射         |
| SALARY     | SALARY         | 数值类型映射            |
| （固定值）      | SOURCE_SYSTEM  | `'ORACLE'`        |
| （系统时间）     | MIGRATION_DATE | CURRENT_TIMESTAMP |

---

### 4. 迁移结果验证

```sql
SELECT COUNT(*) FROM EMPLOYEES_MIGRATED;
```

结果为 **8 条记录**，与 Oracle 源表一致，迁移成功。

---

## 五、作业 4：Snowflake 聚合数据抽取

### 1. 作业目标

基于 Snowflake 表 `TRANSACTIONS`，按支付方式进行交易数据聚合分析。

---

### 2. 使用的 SQL 查询

```sql
SELECT
    PAYMENT_METHOD,
    COUNT(*) AS TRANSACTION_COUNT,
    SUM(AMOUNT) AS TOTAL_AMOUNT,
    AVG(AMOUNT) AS AVG_AMOUNT
FROM TRANSACTIONS
GROUP BY PAYMENT_METHOD
ORDER BY TOTAL_AMOUNT DESC;
```

---

### 3. 输出结果确认

成功生成 CSV 文件，内容如下：

```csv
PAYMENT_METHOD,TRANSACTION_COUNT,TOTAL_AMOUNT,AVG_AMOUNT
CREDIT_CARD,4,184000,46000.00
BANK_TRANSFER,2,45000,22500.00
CASH,2,47000,23500.00
```

---

## 六、作业 5：数据类型映射比较总结

| Oracle 型  | Snowflake 型       | DataStage 型 | 注意点    |
| --------- | ----------------- | ----------- | ------ |
| VARCHAR2  | VARCHAR           | VarChar     | 长度限制   |
| NUMBER    | DECIMAL           | Decimal     | 精度与小数位 |
| DATE      | DATE              | Date        | 格式一致   |
| TIMESTAMP | TIMESTAMP_NTZ     | Timestamp   | 无时区    |
| CLOB      | VARCHAR(16777216) | LongVarChar | 最大长度限制 |

---

## 七、学习总结

通过 Day 4 的学习与实践，掌握了以下核心能力：

* DataStage 与 Snowflake 的连接配置方法
* CSV 数据加载至云数据仓库的实现流程
* Oracle → Snowflake 的跨平台数据迁移
* 云数据仓库中的聚合查询与数据抽取
* 不同数据库之间数据类型差异的处理方式

