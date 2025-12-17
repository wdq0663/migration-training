# SQL 基础语法对比：Oracle vs Snowflake

## 培训学员信息
- 姓名：王东强
- 日期：2025-12-16
- 任务：Day 02 - SQL 语法对比练习

---

## 1. 基础查询语法

### 1.1 FROM 子句差异

**Oracle：**
```sql
-- Oracle 需要 DUAL 表来执行无表查询
SELECT SYSDATE FROM DUAL;
SELECT 1 + 1 FROM DUAL;
SELECT USER FROM DUAL;
```

**Snowflake：**
```sql
-- Snowflake 不需要 DUAL 表
SELECT CURRENT_TIMESTAMP();
SELECT 1 + 1;
SELECT CURRENT_USER();
```

**差异总结：**
- Snowflake 支持无 FROM 子句的查询
- Oracle 必须使用 DUAL 伪表

---

## 2. 日期和时间函数

### 2.1 获取当前时间

| 功能 | Oracle | Snowflake | 备注 |
|------|--------|-----------|------|
| 当前日期 | `SYSDATE` | `CURRENT_DATE()` | Snowflake 需要括号 |
| 当前时间戳 | `SYSTIMESTAMP` | `CURRENT_TIMESTAMP()` | Snowflake 精度更高 |
| 当前时间 | `SYSDATE` | `CURRENT_TIME()` | - |

**示例对比：**
```sql
-- Oracle
SELECT SYSDATE,           -- 2025-01-16 14:30:00
       SYSTIMESTAMP       -- 2025-01-16 14:30:00.123456 +08:00
FROM DUAL;

-- Snowflake
SELECT CURRENT_DATE(),           -- 2025-01-16
       CURRENT_TIMESTAMP(),      -- 2025-01-16 14:30:00.123 +0000
       CURRENT_TIME();           -- 14:30:00.123
```

### 2.2 日期计算

**Oracle：**
```sql
-- 加减天数：直接 +/- 数字
SELECT SYSDATE + 7 AS next_week,
       SYSDATE - 30 AS last_month
FROM DUAL;

-- 加减月份：使用 ADD_MONTHS
SELECT ADD_MONTHS(SYSDATE, 3) AS next_quarter
FROM DUAL;
```

**Snowflake：**
```sql
-- 使用 DATEADD 函数
SELECT DATEADD(DAY, 7, CURRENT_DATE()) AS next_week,
       DATEADD(DAY, -30, CURRENT_DATE()) AS last_month,
       DATEADD(MONTH, 3, CURRENT_DATE()) AS next_quarter;

-- 或使用 INTERVAL（更接近标准 SQL）
SELECT CURRENT_DATE() + INTERVAL '7 days' AS next_week,
       CURRENT_DATE() - INTERVAL '30 days' AS last_month;
```

---

## 3. 字符串处理

### 3.1 字符串拼接

**Oracle：**
```sql
-- 使用 || 运算符
SELECT 'Hello' || ' ' || 'World' AS greeting FROM DUAL;
-- 结果：Hello World

-- 使用 CONCAT 函数（仅支持两个参数）
SELECT CONCAT('Hello', 'World') AS greeting FROM DUAL;
-- 结果：HelloWorld
```

**Snowflake：**
```sql
-- 使用 || 运算符（推荐）
SELECT 'Hello' || ' ' || 'World' AS greeting;
-- 结果：Hello World

-- 使用 CONCAT 函数（支持多个参数）
SELECT CONCAT('Hello', ' ', 'World') AS greeting;
-- 结果：Hello World
```

**差异总结：**
- Snowflake 的 `CONCAT` 函数支持多个参数
- 推荐使用 `||` 运算符以保持兼容性

### 3.2 字符串截取

**Oracle：**
```sql
SELECT SUBSTR('Snowflake', 1, 4) AS result FROM DUAL;
-- 结果：Snow（索引从 1 开始）
```

**Snowflake：**
```sql
SELECT SUBSTR('Snowflake', 1, 4) AS result;
-- 结果：Snow（索引从 1 开始）

-- 也支持 SUBSTRING（标准 SQL）
SELECT SUBSTRING('Snowflake', 1, 4) AS result;
-- 结果：Snow
```

---

## 4. NULL 处理

### 4.1 NULL 值替换

**Oracle：**
```sql
-- 使用 NVL（Oracle 特有）
SELECT NVL(commission, 0) AS commission FROM employees;

-- 使用 COALESCE（标准 SQL）
SELECT COALESCE(commission, 0) AS commission FROM employees;
```

**Snowflake：**
```sql
-- 推荐使用 COALESCE（标准 SQL）
SELECT COALESCE(commission, 0) AS commission FROM employees;

-- 也支持 IFNULL（MySQL 兼容）
SELECT IFNULL(commission, 0) AS commission FROM employees;

-- 也支持 NVL（Oracle 兼容）
SELECT NVL(commission, 0) AS commission FROM employees;
```

**迁移建议：**
- 将 Oracle 的 `NVL` 替换为 `COALESCE`（更标准）
- Snowflake 也支持 `NVL`，但推荐使用 `COALESCE`

---

## 5. 聚合函数

### 5.1 基础聚合

| 函数 | Oracle | Snowflake | 是否兼容 |
|------|--------|-----------|----------|
| COUNT | `COUNT(*)` | `COUNT(*)` | ✅ |
| SUM | `SUM(amount)` | `SUM(amount)` | ✅ |
| AVG | `AVG(amount)` | `AVG(amount)` | ✅ |
| MIN | `MIN(amount)` | `MIN(amount)` | ✅ |
| MAX | `MAX(amount)` | `MAX(amount)` | ✅ |

### 5.2 高级聚合函数

**Oracle：**
```sql
-- LISTAGG 字符串聚合
SELECT department_id,
       LISTAGG(employee_name, ', ') WITHIN GROUP (ORDER BY employee_name) AS employees
FROM employees
GROUP BY department_id;
```

**Snowflake：**
```sql
-- LISTAGG（完全兼容）
SELECT department_id,
       LISTAGG(employee_name, ', ') WITHIN GROUP (ORDER BY employee_name) AS employees
FROM employees
GROUP BY department_id;

-- 或使用 ARRAY_AGG（返回数组）
SELECT department_id,
       ARRAY_AGG(employee_name) AS employees
FROM employees
GROUP BY department_id;
```

---

## 6. JOIN 语法

### 6.1 INNER JOIN

**Oracle（旧语法）：**
```sql
-- Oracle 8i 之前的旧式 JOIN
SELECT e.employee_name, d.department_name
FROM employees e, departments d
WHERE e.department_id = d.department_id;
```

**标准 SQL（Oracle 9i+ & Snowflake）：**
```sql
-- ANSI JOIN 语法（推荐）
SELECT e.employee_name, d.department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;
```

**迁移建议：**
- 将 Oracle 旧式 JOIN 改写为 ANSI JOIN 语法
- Snowflake 也支持旧式 JOIN，但不推荐

### 6.2 OUTER JOIN

**Oracle（旧语法）：**
```sql
-- Oracle 特有的 (+) 语法
SELECT e.employee_name, d.department_name
FROM employees e, departments d
WHERE e.department_id = d.department_id(+);  -- LEFT OUTER JOIN
```

**标准 SQL：**
```sql
-- ANSI OUTER JOIN 语法
SELECT e.employee_name, d.department_name
FROM employees e
LEFT OUTER JOIN departments d ON e.department_id = d.department_id;
```

**重要差异：**
- Snowflake **不支持** Oracle 的 `(+)` 语法
- **必须改写为** ANSI OUTER JOIN 语法

---

## 7. 分页查询

### 7.1 LIMIT 语法

**Oracle：**
```sql
-- Oracle 12c+ 支持 FETCH FIRST
SELECT * FROM employees
ORDER BY employee_id
FETCH FIRST 10 ROWS ONLY;

-- Oracle 11g 及以下使用 ROWNUM
SELECT * FROM (
  SELECT * FROM employees ORDER BY employee_id
) WHERE ROWNUM <= 10;
```

**Snowflake：**
```sql
-- 使用 LIMIT（最简洁）
SELECT * FROM employees
ORDER BY employee_id
LIMIT 10;

-- 也支持 FETCH FIRST（标准 SQL）
SELECT * FROM employees
ORDER BY employee_id
FETCH FIRST 10 ROWS ONLY;
```

### 7.2 分页偏移

**Oracle：**
```sql
-- Oracle 12c+
SELECT * FROM employees
ORDER BY employee_id
OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY;
```

**Snowflake：**
```sql
-- 使用 LIMIT ... OFFSET（最简洁）
SELECT * FROM employees
ORDER BY employee_id
LIMIT 10 OFFSET 20;

-- 也支持标准 SQL 语法
SELECT * FROM employees
ORDER BY employee_id
OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY;
```

---

## 8. 数据类型转换

### 8.1 字符串转数字

**Oracle：**
```sql
SELECT TO_NUMBER('123.45') AS num FROM DUAL;
-- 结果：123.45
```

**Snowflake：**
```sql
-- 使用 TRY_TO_NUMBER（推荐，出错返回 NULL）
SELECT TRY_TO_NUMBER('123.45') AS num;
-- 结果：123.45

-- 使用 TO_NUMBER（出错会抛异常）
SELECT TO_NUMBER('123.45') AS num;
-- 结果：123.45

-- 使用 CAST（标准 SQL）
SELECT CAST('123.45' AS NUMBER) AS num;
-- 结果：123.45
```

### 8.2 日期转字符串

**Oracle：**
```sql
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS date_str FROM DUAL;
-- 结果：2025-01-16 14:30:00
```

**Snowflake：**
```sql
-- 使用 TO_CHAR（Oracle 兼容）
SELECT TO_CHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD HH24:MI:SS') AS date_str;
-- 结果：2025-01-16 14:30:00

-- 使用 TO_VARCHAR（Snowflake 推荐）
SELECT TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD HH24:MI:SS') AS date_str;
-- 结果：2025-01-16 14:30:00
```

---

## 9. 练习总结

### 9.1 主要差异点

| 类别 | Oracle 特性 | Snowflake 替代方案 | 兼容性 |
|------|-------------|-------------------|--------|
| DUAL 表 | 必须使用 | 可省略 | Snowflake 也支持 DUAL |
| (+) JOIN | 支持 | **不支持** | 必须改写为 ANSI JOIN |
| SYSDATE | 无括号 | CURRENT_DATE() 需要括号 | - |
| ROWNUM | 支持 | 不支持，使用 LIMIT | - |
| NVL | 支持 | 推荐用 COALESCE | Snowflake 也支持 NVL |
| SUBSTR | 索引从 1 开始 | 索引从 1 开始 | ✅ 兼容 |

### 9.2 迁移优先级

**高优先级（必须修改）：**
1. 将 `(+)` JOIN 改写为 ANSI OUTER JOIN
2. 将 `ROWNUM` 分页改写为 `LIMIT/OFFSET`
3. 检查并替换 Oracle 专有函数

**中优先级（推荐修改）：**
1. 将 `NVL` 替换为 `COALESCE`
2. 将 `SYSDATE` 替换为 `CURRENT_TIMESTAMP()`
3. 删除不必要的 `FROM DUAL`

**低优先级（可选）：**
1. 统一使用标准 SQL 语法
2. 添加显式类型转换

### 9.3 学习心得

1. **兼容性好：** Snowflake 支持大部分 Oracle 函数，迁移成本较低
2. **标准化程度高：** Snowflake 更倾向于使用标准 SQL 语法
3. **需要测试验证：** 每个改写都需要验证结果一致性

---

## 10. 下一步计划

明天开始学习 **数据类型映射**，重点关注：
- NUMBER vs NUMERIC/DECIMAL
- VARCHAR2 vs VARCHAR
- DATE vs DATE/TIMESTAMP
- CLOB vs VARCHAR
