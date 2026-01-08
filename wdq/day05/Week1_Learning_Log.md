# 坑点 1：Oracle 专有语法在 Snowflake 中直接失效
（典型代表：DUAL、ROWNUM、CONNECT BY）
## 坑点描述
Oracle 中大量“理所当然”的语法在 Snowflake 中不存在或语义完全不同，最容易导致：
SQL 直接报错
逻辑结果错误但不易察觉
## 复现步骤
-- Oracle
SELECT SYSDATE FROM DUAL;

SELECT * FROM orders WHERE ROWNUM <= 10;

SELECT employee_id, manager_id, LEVEL
FROM employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;


在 Snowflake 中执行以上 SQL：

DUAL：❌ 表不存在

ROWNUM：❌ 不支持

CONNECT BY：❌ 不支持

## 解决方案
-- Snowflake 当前时间
SELECT CURRENT_TIMESTAMP();

-- Top N 查询
SELECT *
FROM orders
QUALIFY ROW_NUMBER() OVER (ORDER BY order_id) <= 10;

-- 递归层级查询
WITH RECURSIVE org_cte AS (
    SELECT employee_id, manager_id, 1 AS level
    FROM employees
    WHERE manager_id IS NULL
    UNION ALL
    SELECT e.employee_id, e.manager_id, o.level + 1
    FROM employees e
    JOIN org_cte o
      ON e.manager_id = o.employee_id
)
SELECT * FROM org_cte;

## 预防措施

建立“Oracle 特有语法清单”（DUAL / ROWNUM / CONNECT BY / DECODE）
迁移前 全库 SQL 扫描（正则或脚本）
高风险 SQL 必须 双库结果对比验证


# 坑点 2：数据类型“看起来一样，其实不一样”
（精度、时区、隐式转换）

## 坑点描述
Oracle → Snowflake 的数据类型映射如果“凭感觉”，非常容易：
金额精度丢失
日期/时间偏移
字符串被截断

## 复现步骤

-- Oracle
SALARY NUMBER(10,2)
ORDER_DATE DATE
DESCRIPTION CLOB


错误迁移示例：
-- Snowflake（错误）
SALARY FLOAT;
ORDER_DATE DATE;
DESCRIPTION VARCHAR(255);


问题：
FLOAT → 金额精度不可控
DATE → Snowflake 中无时间部分
VARCHAR(255) → CLOB 数据被截断

## 解决方案
-- Snowflake（正确）

SALARY NUMBER(10,2);
ORDER_DATE TIMESTAMP_NTZ;
DESCRIPTION VARCHAR; -- 或 VARIANT

## 预防措施
禁止使用 FLOAT 存储金额
日期字段统一确认：
是否需要时间
是否涉及时区（NTZ / LTZ / TZ）
建立 Oracle → Snowflake 数据类型映射表
每张表迁移后必须做：
COUNT(*)
SUM(金额字段)
MIN/MAX(日期字段)


# 坑点 3：函数“能跑 ≠ 等价”
（NVL / DECODE / 字符串拼接 / 日期函数）

## 坑点描述
部分函数在 Snowflake 中：
语法可用
但行为与 Oracle 不完全一致
这是最隐蔽、最容易漏测的一类问题。
## 复现步骤
-- Oracle
SELECT NVL(NULL, 'A') FROM DUAL;
SELECT 'A' || NULL FROM DUAL;  -- 返回 'A'

-- Snowflake
SELECT NVL(NULL, 'A');         -- OK
SELECT 'A' || NULL;            -- 返回 NULL ❌

## 解决方案
-- 推荐写法
SELECT COALESCE(col, 'A');

-- 字符串拼接安全写法
SELECT COALESCE(col1, '') || COALESCE(col2, '');


DECODE 转换：

-- Oracle
DECODE(status, 'A', 'ACTIVE', 'I', 'INACTIVE', 'UNKNOWN')

-- Snowflake
CASE
  WHEN status = 'A' THEN 'ACTIVE'
  WHEN status = 'I' THEN 'INACTIVE'
  ELSE 'UNKNOWN'
END

## 预防措施
禁止“逐字翻译”函数
所有函数迁移必须回答一个问题：
NULL 输入时，行为是否完全一致？
关键字段必须做：
NULL 场景测试
边界值测试


SQL 语法级高风险项

| 场景    | Oracle 写法                  | Snowflake 写法                 | 风险点                | 推荐做法                       |
| ----- | -------------------------- | ---------------------------- | ------------------ | -------------------------- |
| 当前时间  | `SELECT SYSDATE FROM DUAL` | `SELECT CURRENT_TIMESTAMP()` | Snowflake 无 `DUAL` | 统一使用 `CURRENT_TIMESTAMP()` |
| Top N | `WHERE ROWNUM <= 10`       | ❌ 不支持                        | 逻辑完全失效             | `ROW_NUMBER() + QUALIFY`   |
| 层级查询  | `CONNECT BY`               | ❌ 不支持                        | 需重写逻辑              | 递归 CTE                     |
| 虚表    | `DUAL`                     | ❌ 不存在                        | SQL 报错             | 直接 `SELECT 常量`             |
| 隐式排序  | `ROWNUM`                   | ❌                            | 顺序不确定              | **必须显式 ORDER BY**          |


数据类型映射高风险项

金额 & 数值类

| Oracle         | ❌ 错误 Snowflake | ✅ 正确 Snowflake | 风险                |
| -------------- | -------------- | -------------- | ----------------- |
| `NUMBER(10,2)` | `FLOAT`        | `NUMBER(10,2)` | 精度丢失              |
| `NUMBER`       | `FLOAT`        | `NUMBER(38,0)` | 隐式四舍五入            |
| `INTEGER`      | `INTEGER`      | `NUMBER(38,0)` | Snowflake 无真正 INT |

日期 / 时间类型

| Oracle              | Snowflake 可选    | 使用建议     |
| ------------------- | --------------- | -------- |
| `DATE`              | `DATE`          | ❌ 会丢时间   |
| `DATE`              | `TIMESTAMP_NTZ` | ✅ 默认推荐   |
| `TIMESTAMP`         | `TIMESTAMP_LTZ` | ⚠ 涉及时区才用 |
| `TIMESTAMP WITH TZ` | `TIMESTAMP_TZ`  | 必须确认业务   |

大字段

| Oracle      | Snowflake      | 风险     |
| ----------- | -------------- | ------ |
| `CLOB`      | `VARCHAR(255)` | ❌ 数据截断 |
| `CLOB`      | `VARCHAR`      | ✅ 推荐   |
| `BLOB`      | `BINARY`       | ⚠ 编码差异 |
| `JSON CLOB` | `VARIANT`      | ✅ 推荐   |


函数语义高风险项

NULL 行为不一致

| 场景      | Oracle     | Snowflake  | 风险          |      |   |              |          |
| ------- | ---------- | ---------- | ----------- | ---- | - | ------------ | -------- |
| NULL 替换 | `NVL(a,b)` | `NVL(a,b)` | 行为接近        |      |   |              |          |
| 拼接      | `'A'       |            | NULL = 'A'` | `'A' |   | NULL = NULL` | **结果不同** |

条件判断

| Oracle   | Snowflake           | 风险    |
| -------- | ------------------- | ----- |
| `DECODE` | `CASE WHEN` / `IFF` | 需人工重写 |
| 隐式 ELSE  | 默认 NULL             | 必须显式  |

日期函数

| Oracle            | Snowflake                 | 风险   |
| ----------------- | ------------------------- | ---- |
| `ADD_MONTHS(d,n)` | `DATEADD(MONTH,n,d)`      | 闰月差异 |
| `TRUNC(date)`     | `DATE_TRUNC('DAY', date)` | 精度不同 |

查询语义高风险项

| 场景         | Oracle 行为 | Snowflake 行为 | 风险     |
| ---------- | --------- | ------------ | ------ |
| 无 ORDER BY | 常“看起来有序”  | 完全无序         | 结果漂移   |
| GROUP BY   | 宽松        | 严格           | SQL 报错 |
| 空字符串       | 等同 NULL   | 非 NULL       | 逻辑变化   |

DML / 事务差异

| 场景          | Oracle | Snowflake |
| ----------- | ------ | --------- |
| 自动提交        | 否      | 是         |
| UPDATE JOIN | 支持     | ❌         |
| MERGE       | 支持     | 支持（语法不同）  |
