Oracle → Snowflake 迁移常见坑点手册

Migration Pitfalls Handbook

本手册总结 Oracle 数据库向 Snowflake 迁移过程中最常见、最容易踩坑的问题，覆盖 SQL 语法、数据类型、性能优化及 JDBC 连接四大方面，用于团队内部知识沉淀与迁移避坑参考。

Part 1：SQL 语法坑点（12 个）
| 坑点          | Oracle 写法             | 错误的 Snowflake 写法 | 正确的 Snowflake 写法                      | 说明                   |      |   |      |               |
| ----------- | --------------------- | ---------------- | ------------------------------------- | -------------------- | ---- | - | ---- | ------------- |
| ROWNUM      | `WHERE ROWNUM <= 10`  | 直接使用 ROWNUM      | `LIMIT 10` 或 `ROW_NUMBER()`           | Snowflake 不支持 ROWNUM |      |   |      |               |
| NVL         | `NVL(col,0)`          | `NVL(col,0)`     | `COALESCE(col,0)`                     | Snowflake 不支持 NVL    |      |   |      |               |
| DECODE      | `DECODE(a,1,'Y','N')` | 直接照搬             | `CASE WHEN a=1 THEN 'Y' ELSE 'N' END` | 需改写为 CASE            |      |   |      |               |
| SYSDATE     | `SYSDATE`             | `SYSDATE`        | `CURRENT_TIMESTAMP()`                 | 函数名不同                |      |   |      |               |
| DUAL 表      | `SELECT 1 FROM DUAL`  | 使用 DUAL          | `SELECT 1`                            | Snowflake 不需要 DUAL   |      |   |      |               |
| MERGE 语法差异  | Oracle MERGE          | 完全照抄             | 使用 Snowflake MERGE                    | WHEN MATCHED 语法有差异   |      |   |      |               |
| 字符串拼接       | `'A'                  |                  | 'B'`                                  | 通常可用                 | `'A' |   | 'B'` | 可用但注意 NULL 行为 |
| 日期加减        | `SYSDATE+1`           | 直接加减             | `DATEADD(day,1,col)`                  | Snowflake 不支持隐式日期运算  |      |   |      |               |
| TRUNC(date) | `TRUNC(date)`         | 直接使用             | `DATE_TRUNC('day',date)`              | 函数语义不同               |      |   |      |               |
| 子查询别名       | `FROM (SELECT...)`    | 无别名              | 必须加别名                                 | Snowflake 强制要求       |      |   |      |               |
| UPDATE JOIN | Oracle UPDATE JOIN    | 直接照抄             | 使用 MERGE 或子查询                         | 语法不兼容                |      |   |      |               |
| DELETE JOIN | Oracle DELETE JOIN    | 直接照抄             | `DELETE FROM t USING t2`              | 语法差异                 |      |   |      |               |

Part 2：数据类型坑点（6 个）
| 坑点        | Oracle 行为           | Snowflake 行为   | 风险说明   | 建议           |
| --------- | ------------------- | -------------- | ------ | ------------ |
| NUMBER 精度 | `NUMBER` → (38,127) | `NUMBER(38,0)` | 小数被截断  | 显式定义精度       |
| DATE 类型   | 含日期+时间              | 仅日期            | 时间信息丢失 | 改用 TIMESTAMP |
| TIMESTAMP | 多种子类型               | NTZ/LTZ/TZ     | 时区混乱   | 明确选择类型       |
| VARCHAR2  | VARCHAR2            | VARCHAR        | 长度限制不同 | 显式定义长度       |
| CHAR 补空格  | 自动补齐                | 不补齐            | 比较结果不同 | 避免 CHAR      |
| CLOB      | CLOB                | VARCHAR        | 超长数据风险 | 检查最大长度       |

Part 3：性能优化坑点（5 个）
| 坑点        | Oracle 思维   | Snowflake 现实 | 影响   | 正确做法              |
| --------- | ----------- | ------------ | ---- | ----------------- |
| 索引        | B-Tree 索引   | 无索引          | 查询慢  | 使用 Clustering Key |
| Hint      | 强制执行计划      | Hint 被忽略     | 优化失效 | 交给优化器             |
| 分区表       | 手动分区        | 自动微分区        | 分区无效 | 设计好过滤条件           |
| 小表 Join   | Nested Loop | Hash Join    | 性能波动 | 控制 Join 顺序        |
| 频繁 UPDATE | OLTP 更新     | 列式存储         | 性能差  | 改为 INSERT + MERGE |

Part 4：JDBC 连接坑点（4 个）
| 坑点             | 错误表现    | 原因              | 解决方案                   |
| -------------- | ------- | --------------- | ---------------------- |
| JDBC URL 缺参数   | 能连但查表失败 | 未指定 db/schema   | URL 中显式配置              |
| 大小写问题          | 表不存在    | Snowflake 区分大小写 | 统一使用大写                 |
| Session Schema | 查错表     | 默认 schema 不一致   | 登录后 SET schema         |
| 超时配置           | 查询被中断   | Warehouse 自动挂起  | 调整 timeout & warehouse |
