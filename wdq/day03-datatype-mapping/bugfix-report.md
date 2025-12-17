# Day03 学习笔记：Oracle → Snowflake 数据类型映射 Bug 修复报告

## 背景
在 Oracle 到 Snowflake 的迁移过程中，数据类型映射错误是最常见、也是最容易被忽视的数据质量风险。本学习笔记基于 Mentor 提供的 5 个典型错误迁移案例，总结问题原因、修复方案以及数据一致性验证方法。

---

## 案例 1：NUMBER 精度丢失

### Oracle 原表 DDL
```sql
CREATE TABLE ORDERS (
  ORDER_ID NUMBER(18,0),
  TOTAL_AMOUNT NUMBER(18,6)
);
错误的 Snowflake 迁移 DDL
sql

CREATE TABLE ORDERS (
  ORDER_ID INTEGER,
  TOTAL_AMOUNT FLOAT
);
数据丢失 / 精度问题说明
NUMBER(18,0) 被映射为 INTEGER，可能超出 Snowflake INTEGER 范围导致溢出

NUMBER(18,6) 被映射为 FLOAT，会产生浮点精度误差，金额类数据不准确

修复后的 Snowflake DDL
sql

CREATE TABLE ORDERS (
  ORDER_ID NUMBER(18,0),
  TOTAL_AMOUNT NUMBER(18,6)
);
数据验证 SQL
sql

-- 验证金额字段是否存在精度异常
SELECT COUNT(*) AS diff_cnt
FROM ORDERS
WHERE TOTAL_AMOUNT != CAST(TOTAL_AMOUNT AS NUMBER(18,6));
错误原因分析
错误认为 Snowflake 的浮点类型可以安全替代高精度数值类型。

修复方案说明
Snowflake NUMBER(p,s) 与 Oracle NUMBER(p,s) 语义一致，应优先使用以保证数值精度。

案例 2：Oracle DATE 语义被错误简化
Oracle 原表 DDL
sql

CREATE TABLE USER_LOGIN (
  USER_ID NUMBER,
  LOGIN_TIME DATE
);
错误的 Snowflake 迁移 DDL
sql

CREATE TABLE USER_LOGIN (
  USER_ID NUMBER,
  LOGIN_TIME DATE
);
数据丢失 / 精度问题说明
Oracle 的 DATE 实际包含日期和时间（精确到秒），而 Snowflake 的 DATE 仅保留日期部分，时间信息被截断。

修复后的 Snowflake DDL
sql

CREATE TABLE USER_LOGIN (
  USER_ID NUMBER,
  LOGIN_TIME TIMESTAMP_NTZ
);
数据验证 SQL
sql

-- 验证是否存在非 00:00:00 的时间数据
SELECT COUNT(*)
FROM USER_LOGIN
WHERE DATE_PART(HOUR, LOGIN_TIME) <> 0;
错误原因分析
忽略了 Oracle DATE 类型包含时间信息的事实。

修复方案说明
Oracle DATE 应映射为 Snowflake TIMESTAMP_NTZ 以完整保留时间语义。

案例 3：CHAR 定长字段语义丢失
Oracle 原表 DDL
sql

CREATE TABLE COUNTRY (
  CODE CHAR(2),
  NAME VARCHAR2(50)
);
错误的 Snowflake 迁移 DDL
sql

CREATE TABLE COUNTRY (
  CODE VARCHAR(2),
  NAME VARCHAR(50)
);
数据问题说明
将 CHAR(2) 映射为 VARCHAR(2) 会导致定长语义丢失，影响基于字符串长度或补空格的业务逻辑。

修复后的 Snowflake DDL
sql

CREATE TABLE COUNTRY (
  CODE CHAR(2),
  NAME VARCHAR(50)
);
数据验证 SQL
sql

-- 验证 CODE 字段是否全部为定长 2
SELECT COUNT(*)
FROM COUNTRY
WHERE LENGTH(CODE) <> 2;
错误原因分析
误以为 Snowflake 中 CHAR 与 VARCHAR 没有实际差异。

修复方案说明
Snowflake 支持 CHAR 类型，迁移时应保持原始字段语义不变。

案例 4：CLOB 被错误当作普通字符串
Oracle 原表 DDL
sql

CREATE TABLE ARTICLE (
  ID NUMBER,
  CONTENT CLOB
);
错误的 Snowflake 迁移 DDL
sql

CREATE TABLE ARTICLE (
  ID NUMBER,
  CONTENT VARCHAR(16777216)
);
数据问题说明
在数据加载或 ETL 过程中，超长文本可能被截断，造成内容丢失。

修复后的 Snowflake DDL
sql

CREATE TABLE ARTICLE (
  ID NUMBER,
  CONTENT STRING
);
数据验证 SQL
sql

-- 检查内容字段最大长度
SELECT MAX(LENGTH(CONTENT)) FROM ARTICLE;
错误原因分析
仅关注物理长度限制，忽略了大对象字段的逻辑语义。

修复方案说明
Snowflake 推荐使用 STRING 作为大文本字段的抽象类型。

案例 5：NUMBER(1) 被误映射为 BOOLEAN
Oracle 原表 DDL
sql

CREATE TABLE FEATURE_FLAG (
  FLAG_VALUE NUMBER(1)
);
错误的 Snowflake 迁移 DDL
sql

CREATE TABLE FEATURE_FLAG (
  FLAG_VALUE BOOLEAN
);
数据问题说明
Oracle NUMBER(1) 字段可能存储多种状态值（如 0、1、2、9），映射为 BOOLEAN 会导致非法值无法加载或被错误转换。

修复后的 Snowflake DDL
sql

CREATE TABLE FEATURE_FLAG (
  FLAG_VALUE NUMBER(1)
);
数据验证 SQL
sql

-- 检查是否存在非布尔语义的数据
SELECT DISTINCT FLAG_VALUE
FROM FEATURE_FLAG
WHERE FLAG_VALUE NOT IN (0,1);
错误原因分析
在迁移阶段进行了过度的业务语义推断。

修复方案说明
迁移应优先保证结构和数据保真，业务语义转换应放在后续处理阶段。